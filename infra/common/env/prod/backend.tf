terraform {
  backend "s3" {
    bucket  = "larabel-app-terraform-state"
    key     = "common/env/prod/terraform.tfstate"
    region  = "ap-northeast-1"
    encrypt = true
  }
}
