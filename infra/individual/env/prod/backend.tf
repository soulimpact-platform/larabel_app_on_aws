terraform {
  backend "s3" {
    # stateバケットはcommon側のbootstrapで作成したものを共用し、
    # keyを分けることでcommonとは独立したstateにする
    bucket = "larabel-app-terraform-state"
    key    = "individual/env/prod/terraform.tfstate"
    region = "ap-northeast-1"

    encrypt = true

    # S3ネイティブのstateロック（Terraform 1.10以降）
    use_lockfile = true
  }
}
