project     = "larabel-app"
environment = "prod"
region      = "ap-northeast-1"

# ECRモジュールの設定（キーがリポジトリ名の接尾辞になる）
#   app   → larabel-app-prod-app    php-fpm
#   nginx → larabel-app-prod-nginx  リバースプロキシ
ecr = {
  app = {
    image_tag_mutability = "MUTABLE" # latestタグを更新するため
    keep_image_count     = 10
    force_delete         = true # 検証中のためイメージが残っていても削除可能にする
  }
  nginx = {
    image_tag_mutability = "MUTABLE"
    keep_image_count     = 10
    force_delete         = true
  }
}

# GitHub ActionsがOIDCで引き受けるロールの設定
github = {
  role_name = "github-actions"

  # GitHub Environment を指定したジョブからのみ引き受けを許可する。
  # ジョブに environment を書き忘れるとsubがブランチ形式に戻り認証に失敗する
  allowed_subjects = [
    "repo:soulimpact-platform/larabel_app_on_aws:environment:app-prod",
    "repo:soulimpact-platform/larabel_app_on_aws:environment:app-prod-migrate",
  ]
}

# 公開ドメイン。ホストゾーンは既存のものを参照する（作成はしない）
dns = {
  zone_name   = "sukunahikona.org"
  record_name = "alb-larabel" # → alb-larabel.sukunahikona.org
}

# ALBモジュールの設定
alb = {
  allowed_cidrs     = ["0.0.0.0/0"]
  target_port       = 80
  health_check_path = "/up" # Laravelが標準で用意するヘルスチェック経路

  deregistration_delay = 30 # デプロイ時の切り替えを速くする
  idle_timeout         = 60
  ssl_policy           = "ELBSecurityPolicy-TLS13-1-2-2021-06"

  # 検証中のため削除しやすい設定。本運用時は true に変更すること
  enable_deletion_protection = false
}

# ECSモジュールの設定
ecs = {
  container_name        = "app"
  nginx_container_name  = "nginx"
  log_retention_in_days = 30

  # Privateサブネットに配置しNAT Gateway経由で外へ出るためfalse
  assign_public_ip = false

  migrate = {
    cpu    = "512"  # 0.5 vCPU
    memory = "1024" # 1GB
  }

  web = {
    cpu           = "512"  # 0.5 vCPU（nginx + php-fpm の合計）
    memory        = "1024" # 1GB
    desired_count = 1      # コスト優先。可用性が必要になったら2以上へ

    # ALBのヘルスチェックが通るまでの猶予。Laravelの初回起動を待つ
    health_check_grace_period_seconds = 60
  }
}
