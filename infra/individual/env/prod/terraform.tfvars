project     = "larabel-app"
environment = "prod"
region      = "ap-northeast-1"

# ECRモジュールの設定（Laravelアプリのコンテナイメージ置き場）
ecr = {
  repository_name      = "app"
  image_tag_mutability = "MUTABLE" # latestタグを更新するため
  keep_image_count     = 10        # 直近10世代のみ保持
  force_delete         = true      # 検証中のためイメージが残っていても削除可能にする
}

# GitHub ActionsがOIDCで引き受けるロールの設定
github = {
  role_name = "github-actions"

  # GitHub Environment "app-prod" を指定したジョブからのみ引き受けを許可する。
  #
  # ジョブに environment を指定すると、JWTのsubクレームは
  # ブランチ名ではなく environment:<name> の形になる。
  # そのためブランチを問わず、かつ「app-prod環境を使うジョブ」に限定できる。
  #
  # Environment側にReviewer等の保護ルールを掛ければ、
  # AWSを触れる条件をGitHub側からも制御できるのが利点。
  allowed_subjects = [
    "repo:soulimpact-platform/larabel_app_on_aws:environment:app-prod",
    "repo:soulimpact-platform/larabel_app_on_aws:environment:app-prod-migrate",
  ]
}

# ECSモジュールの設定（migrate実行用）
ecs = {
  container_name        = "app"
  log_retention_in_days = 30

  migrate = {
    cpu    = "512"  # 0.5 vCPU
    memory = "1024" # 1GB
  }
}
