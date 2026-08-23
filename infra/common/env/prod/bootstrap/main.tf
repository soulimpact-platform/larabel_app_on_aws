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
    # 初期の社内管理者アカウント。
    #
    # 本番のmigrateタスクは --seed を実行しないため、DatabaseSeederが作る
    # admin@example.com は本番には存在しない。代わりにCIから
    # `php artisan app:create-admin-user` を一度だけ実行して発行する。
    #
    # 実値はapply後にCLIで設定する:
    #   aws ssm put-parameter --name /larabel-app/prod/app/admin_email \
    #     --value 'owner@example.com' --type String --overwrite
    #   aws ssm put-parameter --name /larabel-app/prod/app/admin_password \
    #     --value "$(openssl rand -base64 24)" --type SecureString --overwrite
    "app/admin_email" = {
      value       = var.admin_email
      type        = "String"
      description = "Initial admin user email"
    }

    "app/admin_name" = {
      value       = var.admin_name
      type        = "String"
      description = "Initial admin user display name"
    }

    "app/admin_password" = {
      value       = var.admin_password
      type        = "SecureString"
      description = "Initial admin user password"
    }

    "cloudfront/origin_verify" = {
      value       = var.cloudfront_origin_verify
      type        = "SecureString"
      description = "Shared secret header value between CloudFront and ALB"
    }
  }
}
