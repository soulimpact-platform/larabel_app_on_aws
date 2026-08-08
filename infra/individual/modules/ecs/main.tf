data "aws_partition" "current" {}
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# SecureStringの復号に使うAWSマネージドキー。
# ECSがsecretsを解決する際にタスク実行ロールがこの鍵で復号する
data "aws_kms_alias" "ssm" {
  name = "alias/aws/ssm"
}

locals {
  name = "${var.project}-${var.environment}"

  # DB認証情報を置いているSSMパラメータのARN接頭辞
  ssm_rds_prefix = "arn:${data.aws_partition.current.partition}:ssm:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:parameter/${var.project}/${var.environment}/rds"
}

###############################################################################
# CloudWatch Logs
#
# migrateの実行結果はここにしか残らない。失敗時の原因確認に必須
###############################################################################
resource "aws_cloudwatch_log_group" "this" {
  name              = "/ecs/${local.name}"
  retention_in_days = var.ecs.log_retention_in_days

  tags = {
    Name = "/ecs/${local.name}"
  }
}

###############################################################################
# ECS Cluster
###############################################################################
resource "aws_ecs_cluster" "this" {
  name = local.name

  setting {
    name  = "containerInsights"
    value = "disabled" # コスト優先。監視が必要になったらenabledへ
  }

  tags = {
    Name = local.name
  }
}

###############################################################################
# タスク実行ロール（ECSエージェントが使う）
#
# コンテナを起動する「前」に使われる権限。
# ECRからのイメージpull、CloudWatch Logsへの書き込み、
# secretsで指定したSSMパラメータの取得を担う。
# アプリケーション自身の権限ではない点に注意。
###############################################################################
data "aws_iam_policy_document" "ecs_tasks_assume" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "task_execution" {
  name               = "${local.name}-ecs-task-execution"
  description        = "ECS task execution role (image pull / logs / secrets)"
  assume_role_policy = data.aws_iam_policy_document.ecs_tasks_assume.json

  tags = {
    Name = "${local.name}-ecs-task-execution"
  }
}

resource "aws_iam_role_policy_attachment" "task_execution" {
  role       = aws_iam_role.task_execution.name
  policy_arn = "arn:${data.aws_partition.current.partition}:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# DB認証情報の取得。対象を /project/env/rds/* に限定する
data "aws_iam_policy_document" "task_execution_secrets" {
  statement {
    sid       = "ReadRdsParameters"
    effect    = "Allow"
    actions   = ["ssm:GetParameters"]
    resources = ["${local.ssm_rds_prefix}/*"]
  }

  statement {
    sid       = "DecryptSecureString"
    effect    = "Allow"
    actions   = ["kms:Decrypt"]
    resources = [data.aws_kms_alias.ssm.target_key_arn]
  }
}

resource "aws_iam_role_policy" "task_execution_secrets" {
  name   = "${local.name}-ecs-task-execution-secrets"
  role   = aws_iam_role.task_execution.id
  policy = data.aws_iam_policy_document.task_execution_secrets.json
}

###############################################################################
# タスクロール（コンテナ内のアプリケーションが使う）
#
# migrateはAWS APIを呼ばないため権限は空。
# 将来S3やSESを使うようになったらここにポリシーを足す。
###############################################################################
resource "aws_iam_role" "task" {
  name               = "${local.name}-ecs-task"
  description        = "ECS task role (used by the application itself)"
  assume_role_policy = data.aws_iam_policy_document.ecs_tasks_assume.json

  tags = {
    Name = "${local.name}-ecs-task"
  }
}

###############################################################################
# migrate用タスク定義
#
# imageは latest を初期値としているが、CI側で実行のたびに
# 「このリビジョンのimageをコミットSHAに差し替えた新リビジョン」を
# 登録してから起動する。そのためTerraform管理下のリビジョンと
# 実行されるリビジョンは異なる（タスク定義は不変オブジェクトのため競合しない）。
###############################################################################
resource "aws_ecs_task_definition" "migrate" {
  family                   = "${local.name}-migrate"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = var.ecs.migrate.cpu
  memory                   = var.ecs.migrate.memory
  execution_role_arn       = aws_iam_role.task_execution.arn
  task_role_arn            = aws_iam_role.task.arn

  runtime_platform {
    operating_system_family = "LINUX"
    # GitHub Actionsのrunner(x86_64)でビルドしたイメージに合わせる
    cpu_architecture = "X86_64"
  }

  # コンテナ定義は container_definitions/migrate.json.tftpl に切り出している。
  # 差し込む値だけをここで渡す
  container_definitions = templatefile(
    "${path.module}/container_definitions/migrate.json.tftpl",
    {
      container_name = var.ecs.container_name
      image          = "${var.ecr_repository_url}:latest"
      db_host        = var.db.host
      db_port        = tostring(var.db.port)
      log_group      = aws_cloudwatch_log_group.this.name
      region         = data.aws_region.current.name
      ssm_rds_prefix = local.ssm_rds_prefix
    }
  )

  tags = {
    Name = "${local.name}-migrate"
  }
}

###############################################################################
# migrate実行に必要な値をSSMに集約
#
# CIがハードコードする値をこの1つに寄せる。
# ワークフロー側が知る固定値はこのパラメータ名だけになり、
# クラスタ名やタスク定義名を変えてもCIを触らずに済む。
#
# サブネットIDとSG IDはAWSが採番するためTerraformでしか分からず、
# run-task には --network-configuration の指定が必須。
###############################################################################
resource "aws_ssm_parameter" "migrate_runtime" {
  name        = "/${var.project}/${var.environment}/ecs/migrate"
  description = "Runtime parameters used by CI to run the migration task"
  type        = "String"

  value = jsonencode({
    cluster              = aws_ecs_cluster.this.name
    taskDefinitionFamily = aws_ecs_task_definition.migrate.family
    containerName        = var.ecs.container_name
    logGroup             = aws_cloudwatch_log_group.this.name

    networkConfiguration = {
      awsvpcConfiguration = {
        subnets        = var.subnet_ids
        securityGroups = var.security_group_ids
        # PrivateサブネットからNAT Gateway経由で外に出るためDISABLEDでよい
        assignPublicIp = "DISABLED"
      }
    }
  })

  tags = {
    Name = "${local.name}-ecs-migrate-runtime"
  }
}
