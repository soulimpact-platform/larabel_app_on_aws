terraform {
  backend "s3" {
    bucket = "larabel-app-terraform-state"
    key    = "common/env/prod/terraform.tfstate"
    region = "ap-northeast-1"

    encrypt = true

    # S3ネイティブのstateロック（Terraform 1.10以降）
    # keyの隣に .tflock オブジェクトを作って排他制御する（DynamoDBテーブルは不要）
    use_lockfile = true
  }
}
