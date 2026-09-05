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

###############################################################################
# CloudFront→ALBの秘密ヘッダ
#
# bootstrapで作成したSSMパラメータから取得する。パブリックリポジトリのため
# 実値はコードに置かず、CLIで投入する:
#   aws ssm put-parameter --name /larabel-app/prod/cloudfront/origin_verify \
#     --value "$(openssl rand -base64 32)" --type SecureString --overwrite
#
# 注意: この値はALBのリスナールールとCloudFrontのオリジン設定に
# そのまま書き込まれる性質上、tfstateにも記録される。
# tfstateは非公開のS3バケット（暗号化済み）に置いている前提。
###############################################################################
data "aws_ssm_parameter" "cloudfront_origin_verify" {
  name = "/${var.project}/${var.environment}/cloudfront/origin_verify"
}

###############################################################################
# WAFのIP制限で許可する送信元
#
# パブリックリポジトリのためtfvarsには書かず、SSMから取得する。
# 自宅IPを公開するとおおよその居住地域が分かり、標的も特定されるため。
# IPが変わったときも put-parameter + apply だけで済み、コミットは不要。
###############################################################################
data "aws_ssm_parameter" "waf_allowed_ip_cidrs" {
  name = "/${var.project}/${var.environment}/waf/allowed_ip_cidrs"
}

locals {
  # partner_record_name が未設定ならCloudFrontを作らない
  cloudfront_enabled = try(var.dns.partner_record_name, null) != null

  origin_verify_header_value = local.cloudfront_enabled ? data.aws_ssm_parameter.cloudfront_origin_verify.value : ""
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

  # CloudFront経由かどうかをリスナールールで判定するための設定。
  # 秘密値が空のあいだはルールを作らず、従来どおり全パスを転送する
  cloudfront = {
    origin_verify_header_value = local.origin_verify_header_value
    partner_host               = local.cloudfront_enabled ? "${var.dns.partner_record_name}.${var.dns.zone_name}" : ""
  }
}

# パートナー向けの公開経路。ALBの手前に置き、秘密ヘッダを付与する
module "cloudfront" {
  source = "../../modules/cloudfront"
  count  = local.cloudfront_enabled ? 1 : 0

  providers = {
    aws           = aws
    aws.us_east_1 = aws.us_east_1
  }

  project     = var.project
  environment = var.environment
  cloudfront  = var.cloudfront

  dns = {
    zone_name   = var.dns.zone_name
    record_name = var.dns.partner_record_name
  }

  # ALBの生DNS名ではなくFQDNを渡す。CloudFrontはオリジンへHTTPS接続する際に
  # 証明書を検証するため、名前が一致しないと接続できない
  origin_domain_name         = module.alb.fqdn
  origin_verify_header_value = local.origin_verify_header_value
}

# WAF。ALBの手前でリクエストの中身を検査する。
# 現在はCOUNTモードのため一切ブロックせず、マッチの記録だけを行う
module "waf" {
  source = "../../modules/waf"

  project     = var.project
  environment = var.environment

  # 秘密ヘッダはSSM由来のためtfvarsではなくここで合成する。
  # ALBのリスナールールと同じ値を参照するので、片方だけズレることはない
  waf = merge(var.waf, {
    origin_verify_header_value = local.origin_verify_header_value

    # 許可IPもSSM由来。カンマ区切りの文字列をリストへ展開する
    allowed_ip_cidrs = [
      for cidr in split(",", data.aws_ssm_parameter.waf_allowed_ip_cidrs.value) : trimspace(cidr)
    ]
  })

  alb_arn = module.alb.arn
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

# 監視。アラームの定義のみを持ち、通知先トピックはcommon側のものを使う。
# トピックをcommonに置いているのは、メール購読の確認を一度で済ませるため
module "monitoring" {
  source = "../../modules/monitoring"

  project     = var.project
  environment = var.environment
  monitoring  = var.monitoring

  alert_topic_arn = data.terraform_remote_state.common.outputs.alert_topic_arn

  alb = {
    arn_suffix              = module.alb.arn_suffix
    target_group_arn_suffix = module.alb.target_group_arn_suffix
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
