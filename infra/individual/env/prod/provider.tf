terraform {
  required_version = ">= 1.14.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.region

  default_tags {
    tags = {
      Project     = var.project
      Environment = var.environment
      ManagedBy   = "terraform"
    }
  }
}

###############################################################################
# us-east-1 用のプロバイダ
#
# CloudFrontが使えるACM証明書はus-east-1のものだけ、という制約のために必要。
# 用途はCloudFront関連のみで、他のリソースは既定のプロバイダで作る。
###############################################################################
provider "aws" {
  alias  = "us_east_1"
  region = "us-east-1"

  default_tags {
    tags = {
      Project     = var.project
      Environment = var.environment
      ManagedBy   = "terraform"
    }
  }
}
