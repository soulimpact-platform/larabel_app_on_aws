###############################################################################
# SSM Parameter Store からDB情報を取得
#
# db_name / username は String のため通常のdata sourceで取得する。
# password は SecureString のため、tfstateに平文で残らないよう
# ephemeral（値がstateに保存されない）で取得し、
# write-only引数である password_wo へ渡す。
###############################################################################
data "aws_partition" "current" {}
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

locals {
  ssm_prefix = "/${var.project}/${var.environment}/rds"

  # ephemeralリソースはARN指定のみ受け付けるため、パラメータ名から組み立てる
  password_parameter_arn = "arn:${data.aws_partition.current.partition}:ssm:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:parameter${local.ssm_prefix}/password"
}

data "aws_ssm_parameter" "db_name" {
  name = "${local.ssm_prefix}/db_name"
}

data "aws_ssm_parameter" "username" {
  name = "${local.ssm_prefix}/username"
}

ephemeral "aws_ssm_parameter" "password" {
  arn = local.password_parameter_arn
}

###############################################################################
# DB Subnet Group（Privateサブネットに配置）
###############################################################################
resource "aws_db_subnet_group" "this" {
  name       = "${var.project}-${var.environment}-db-subnet-group"
  subnet_ids = var.subnet_ids

  tags = {
    Name = "${var.project}-${var.environment}-db-subnet-group"
  }
}

###############################################################################
# RDS Security Group
#
# egressブロックは意図的に定義していない。RDSは自らアウトバウンド通信を
# 行わないため、Terraformがデフォルトの全許可egressを削除する挙動で問題ない。
###############################################################################
resource "aws_security_group" "rds" {
  name        = "${var.project}-${var.environment}-rds-sg"
  description = "Security group for RDS MySQL"
  vpc_id      = var.vpc_id

  ingress {
    description     = "MySQL from allowed security groups"
    from_port       = var.rds.port
    to_port         = var.rds.port
    protocol        = "tcp"
    security_groups = var.allowed_security_group_ids
  }

  tags = {
    Name = "${var.project}-${var.environment}-rds-sg"
  }
}

###############################################################################
# DB Parameter Group
#
# 文字セットはローカル開発環境（docker-composeのmysql:8.0）および
# Laravelのconfig/database.phpの既定値に合わせる。
###############################################################################
resource "aws_db_parameter_group" "this" {
  name   = "${var.project}-${var.environment}-mysql"
  family = var.rds.parameter_group_family

  parameter {
    name  = "character_set_server"
    value = "utf8mb4"
  }

  parameter {
    name  = "collation_server"
    value = "utf8mb4_unicode_ci"
  }

  tags = {
    Name = "${var.project}-${var.environment}-mysql"
  }

  lifecycle {
    create_before_destroy = true
  }
}

###############################################################################
# RDS Instance（MySQL / Auroraではない）
###############################################################################
resource "aws_db_instance" "this" {
  identifier = "${var.project}-${var.environment}-mysql"

  engine         = "mysql"
  engine_version = var.rds.engine_version
  instance_class = var.rds.instance_class

  # gp3。max_allocated_storageを指定するとストレージ自動スケーリングが有効になる
  allocated_storage     = var.rds.allocated_storage
  max_allocated_storage = var.rds.max_allocated_storage
  storage_type          = "gp3"
  storage_encrypted     = true

  db_name  = data.aws_ssm_parameter.db_name.value
  username = data.aws_ssm_parameter.username.value

  # write-only引数。値はtfstateに保存されない。
  # SSM上のパスワードを変更した場合は password_version を増やして再適用する
  password_wo         = ephemeral.aws_ssm_parameter.password.value
  password_wo_version = var.rds.password_version

  port                   = var.rds.port
  db_subnet_group_name   = aws_db_subnet_group.this.name
  vpc_security_group_ids = [aws_security_group.rds.id]
  parameter_group_name   = aws_db_parameter_group.this.name
  publicly_accessible    = false
  multi_az               = var.rds.multi_az

  backup_retention_period = var.rds.backup_retention_period
  backup_window           = var.rds.backup_window
  maintenance_window      = var.rds.maintenance_window
  copy_tags_to_snapshot   = true

  auto_minor_version_upgrade      = true
  enabled_cloudwatch_logs_exports = var.rds.enabled_cloudwatch_logs_exports

  deletion_protection       = var.rds.deletion_protection
  skip_final_snapshot       = var.rds.skip_final_snapshot
  final_snapshot_identifier = var.rds.skip_final_snapshot ? null : "${var.project}-${var.environment}-mysql-final"

  tags = {
    Name = "${var.project}-${var.environment}-mysql"
  }
}
