###############################################################################
# common側で作成したOIDCプロバイダを参照する
#
# OIDCプロバイダのURLは固定値なので、state経由ではなくdata sourceで直接引く。
#
# 前提: common/env/prod を先にapplyしておくこと。
###############################################################################
data "aws_iam_openid_connect_provider" "github" {
  url = "https://token.actions.githubusercontent.com"
}

###############################################################################
# common側のネットワーク・RDS情報を参照する
#
# VPC・サブネット・RDSはcommonが所有しているため、こちらはstate経由で読む。
# 参照は individual → common の一方向のみ。commonはindividualを知らない。
#
# ECSタスクには rds_client_security_group_id を付与する。
# このSGを着けているだけでRDSの3306に到達できる（RDS側で許可済み）。
###############################################################################
data "terraform_remote_state" "common" {
  backend = "s3"

  config = {
    bucket = "larabel-app-terraform-state"
    key    = "common/env/prod/terraform.tfstate"
    region = "ap-northeast-1"
  }
}

###############################################################################
# Modules
###############################################################################
module "ecr" {
  source = "../../modules/ecr"

  project     = var.project
  environment = var.environment
  ecr         = var.ecr
}

# ALB / ACM証明書 / Route53レコード。アプリの公開口
module "alb" {
  source = "../../modules/alb"

  project     = var.project
  environment = var.environment
  alb         = var.alb
  dns         = var.dns

  vpc_id     = data.terraform_remote_state.common.outputs.vpc_id
  subnet_ids = data.terraform_remote_state.common.outputs.public_subnet_ids
}

module "ecs" {
  source = "../../modules/ecs"

  project     = var.project
  environment = var.environment
  ecs         = var.ecs

  vpc_id = data.terraform_remote_state.common.outputs.vpc_id

  ecr_repository_urls = {
    app   = module.ecr.repository_urls["app"]
    nginx = module.ecr.repository_urls["nginx"]
  }

  subnet_ids = data.terraform_remote_state.common.outputs.private_subnet_ids

  # migrateタスク用。RDSへ到達するためのSG
  security_group_ids = [data.terraform_remote_state.common.outputs.rds_client_security_group_id]

  # Webタスク用。ALBからの受信を許可するSGに加えて付与する
  additional_security_group_ids = [data.terraform_remote_state.common.outputs.rds_client_security_group_id]

  alb = {
    security_group_id = module.alb.security_group_id
    target_group_arn  = module.alb.target_group_arn
  }

  app_url = module.alb.url

  db = {
    host = data.terraform_remote_state.common.outputs.rds_address
    port = data.terraform_remote_state.common.outputs.rds_port
  }
}

module "sts_assume_role" {
  source = "../../modules/sts_assume_role"

  project     = var.project
  environment = var.environment
  github      = var.github

  oidc_provider_arn   = data.aws_iam_openid_connect_provider.github.arn
  ecr_repository_arns = module.ecr.repository_arns

  ecs = {
    cluster_arn              = module.ecs.cluster_arn
    service_arns             = module.ecs.service_arns
    task_role_arns           = module.ecs.task_role_arns
    log_group_arn            = module.ecs.log_group_arn
    ssm_parameter_arn_prefix = module.ecs.ssm_parameter_arn_prefix
  }
}
