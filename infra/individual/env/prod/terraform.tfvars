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

  # mainブランチのワークフローからのみロールを引き受け可能にする
  allowed_subjects = [
    "repo:soulimpact-platform/larabel_app_on_aws:ref:refs/heads/main",
  ]
}
