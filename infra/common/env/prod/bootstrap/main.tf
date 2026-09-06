terraform {
  required_version = ">= 1.14.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.region

  default_tags {
    tags = {
      Project   = var.project
      ManagedBy = "terraform"
    }
  }
}

module "s3_state" {
  source = "../../../modules/s3_state"

  project           = var.project
  environment       = var.environment
  state_bucket_name = var.state_bucket_name
}

module "ssm_parameter" {
  source = "../../../modules/ssm_parameter"

  project     = var.project
  environment = var.environment

  parameters = {
    # Laravelのアプリケーションキー。セッション・暗号化に使われる。
    # 初期値はdummy。`php artisan key:generate --show` の出力を
    # AWS ConsoleまたはCLIで設定すること
    "app/app_key" = {
      value       = var.app_key
      type        = "SecureString"
      description = "Laravel APP_KEY"
    }

    "rds/db_name" = {
      value       = var.db_credentials.db_name
      type        = "String"
      description = "RDS database name"
    }
    "rds/username" = {
      value       = var.db_credentials.username
      type        = "String"
      description = "RDS database username"
    }
    "rds/password" = {
      value       = var.db_credentials.password
      type        = "SecureString"
      description = "RDS database password"
    }

    # CloudWatchアラートの通知先。パブリックリポジトリのため
    # コードには実アドレスを書かず、apply後にCLIで上書きする:
    #   aws ssm put-parameter --name /larabel-app/prod/monitoring/alert_email \
    #     --value 'you@example.com' --type String --overwrite
    "monitoring/alert_email" = {
      value       = var.alert_email
      type        = "String"
      description = "CloudWatch alert notification email"
    }

    # CloudFrontがオリジン(ALB)へ付与する秘密ヘッダの値。
    #
    # ALBのリスナールールがこの値を検証し、CloudFront経由でない
    # /partner/* へのアクセスを403で拒否する。Hostヘッダは詐称できるため
    # 「自分のCloudFrontから来た」ことを示せるのはこの秘密値だけ。
    #
    # 実値はapply後にCLIで設定する:
    #   aws ssm put-parameter --name /larabel-app/prod/cloudfront/origin_verify \
    #     --value "$(openssl rand -base64 32)" --type SecureString --overwrite
    # WAFのIP制限で許可する送信元。カンマ区切りのCIDR。
    #
    # パブリックリポジトリのため自宅IPをtfvarsに書かない。値を公開すると
    # おおよその居住地域が分かり、スキャンの標的も特定されるため。
    #
    # 既定値は誰にも一致しないCIDR。投入し忘れた場合は「全員遮断」に倒れ、
    # 気づかず開放されるより安全側になる。
    #
    # 実値はapply後にCLIで設定する:
    #   aws ssm put-parameter --name /larabel-app/prod/waf/allowed_ip_cidrs \
    #     --value "$(curl -s https://checkip.amazonaws.com)/32" --type String --overwrite
    "waf/allowed_ip_cidrs" = {
      value       = var.waf_allowed_ip_cidrs
      type        = "String"
      description = "Comma separated CIDRs allowed by the WAF IP restriction"
    }

    "cloudfront/origin_verify" = {
      value       = var.cloudfront_origin_verify
      type        = "SecureString"
      description = "Shared secret header value between CloudFront and ALB"
    }
  }
}
