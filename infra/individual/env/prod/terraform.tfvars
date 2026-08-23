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
  zone_name = "sukunahikona.org"

  # 社内向け。ALBを直接指す。WAFのIP制限がかかる
  record_name = "alb-larabel" # → alb-larabel.sukunahikona.org

  # 社外パートナー向け。CloudFrontを指す。
  # ここを消すとCloudFront一式が作られず、導入前の状態に戻る
  partner_record_name = "partner-admin" # → partner-admin.sukunahikona.org
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

# WAF
#   count_only は既定(true)のまま。マネージドルールは誤検知の洗い出し中で、
#   マッチしても遮断しない。
#
#   一方 allowed_ip_cidrs によるIP制限は count_only とは独立に「実際に遮断する」。
#   いまは動作検証のため、誰も一致しないIPを指定して全面ブロックにしている。
#   /status だけが免除されるので、免除ルールが効いているかを目視で確認できる。
#
#   期待する挙動:
#     GET /        → 403（IP不一致 かつ 公開パスでない）
#     GET /status  → 200（公開パスなので免除）
#
#   検証後、自宅IP（119.172.135.203/32）へ差し替える。
#   J:COMの動的IPなので変わりうるが、締め出されてもAWS側の操作には影響しない。
#   新しいIPはWAFのサンプリングされたリクエストで確認できる。
waf = {
  allowed_ip_cidrs = ["200.200.200.200/32"]

  # IP制限を免除するパス。uri_pathを小文字化してから照合される。
  # ドットは正規表現のメタ文字なのでエスケープする（^/favicon.ico$ だと
  # /faviconXico にも一致してしまう）
  #
  # 社外のパートナー管理者は任意のIPから接続するため、IPでは絞れない。
  # /partner 配下にまとめたうえで配下ごと免除し、アクセス制御は
  # アプリ側のミドルウェア（admin / partner-admin のみ）に委ねる。
  public_path_regexes = [
    # --- パートナー領域（社外の担当者が使う） ---
    # ログイン・ログアウトも /partner 配下にあるため、この1行で足りる。
    # 社内向けの /login と /logout はIP制限の対象のまま残す
    "^/partner/",

    # --- 静的アセット・動作確認 ---
    "^/build/", # Viteのビルド成果物（CSS/JS）。これが無いと画面が崩れる
    "^/favicon\\.ico$",
    "^/robots\\.txt$",
    "^/status$", # 外形監視・動作確認用
  ]
}
