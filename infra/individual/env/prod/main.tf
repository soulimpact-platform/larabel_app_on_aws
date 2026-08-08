###############################################################################
# common側で作成したOIDCプロバイダを参照する
#
# terraform_remote_state で common の state を読む方法もあるが、
# OIDCプロバイダのURLは固定値なので data source で直接引く方が
# state同士の結合が生まれず疎に保てる。
#
# 前提: common/env/prod を先にapplyしておくこと。
#       プロバイダが未作成だとこのdata sourceは解決に失敗する。
###############################################################################
data "aws_iam_openid_connect_provider" "github" {
  url = "https://token.actions.githubusercontent.com"
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

module "sts_assume_role" {
  source = "../../modules/sts_assume_role"

  project     = var.project
  environment = var.environment
  github      = var.github

  oidc_provider_arn   = data.aws_iam_openid_connect_provider.github.arn
  ecr_repository_arns = [module.ecr.repository_arn]
}
