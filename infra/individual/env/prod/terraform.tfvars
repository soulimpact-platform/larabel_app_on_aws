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

  # このリポジトリの「ブランチ」から実行されたワークフローであれば
  # ブランチ名を問わず引き受けを許可する（手動実行での検証を優先した設定）。
  #
  # refs/heads/* に限定しているのは、pull_request コンテキストを除外するため。
  # 末尾を "*" だけにすると PR やタグからの実行も通ってしまう。
  # 本運用時は refs/heads/main に戻すこと。
  allowed_subjects = [
    "repo:soulimpact-platform/larabel_app_on_aws:ref:refs/heads/*",
  ]
}
