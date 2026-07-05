project           = "larabel-app"
environment       = "prod"
region            = "ap-northeast-1"
state_bucket_name = "larabel-app-terraform-state"

# DB認証情報（SSM Parameter Storeに保存）
# 初期値はdummy。AWS ConsoleまたはCLIで直接SSMパラメータを更新してください
db_credentials = {
  db_name  = "laravel"
  username = "dummy"
  password = "dummy"
}
