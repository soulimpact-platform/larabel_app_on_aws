project           = "larabel-app"
environment       = "prod"
region            = "ap-northeast-1"
state_bucket_name = "larabel-app-terraform-state"

# Laravelのアプリケーションキー
# 初期値はdummy。apply後に必ず実際の値へ更新すること:
#   docker compose -f app/docker-compose.yml run --rm php php artisan key:generate --show
#   aws ssm put-parameter --name /larabel-app/prod/app/app_key \
#     --value 'base64:...' --type SecureString --overwrite
app_key = "dummy"

# DB認証情報（SSM Parameter Storeに保存）
# 初期値はdummy。AWS ConsoleまたはCLIで直接SSMパラメータを更新してください
db_credentials = {
  db_name  = "laravel"
  username = "dummy"
  password = "dummy"
}
