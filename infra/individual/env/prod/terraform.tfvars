###############################################################################
# prod環境の設定
#
# ここに書くのは次の2種類だけ:
#   ① 環境固有の値（project / dns / github など）
#   ② モジュールの既定値から意図的に外している値（必ず理由をコメントする）
#
# それ以外はモジュール側の既定値を使う。既定値の定義は
#   ../../modules/<name>/variables.tf
# を参照。
###############################################################################

project     = "larabel-app"
environment = "prod"
region      = "ap-northeast-1"

# ECRリポジトリ（キーがリポジトリ名の接尾辞になる）
#   app   → larabel-app-prod-app    php-fpm
#   nginx → larabel-app-prod-nginx  リバースプロキシ
ecr = {
  # 検証中のためイメージが残っていてもリポジトリを削除可能にする（既定: false）
  app   = { force_delete = true }
  nginx = { force_delete = true }
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

alb = {
  # 検証中のため削除保護を外している（既定: true）
  enable_deletion_protection = false
}

ecs = {
  web = {
    # コスト優先で1台。可用性が必要になったら既定の2へ戻す（既定: 2）
    desired_count = 1
  }
}

# monitoring は既定値のまま使用（5XX: 5件/5分、p95: 3秒）
