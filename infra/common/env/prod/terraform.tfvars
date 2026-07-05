project     = "larabel-app"
environment = "prod"
region      = "ap-northeast-1"

# VPCモジュールの設定
vpc = {
  cidr                 = "10.0.0.0/16"
  public_subnet_cidrs  = ["10.0.1.0/24", "10.0.2.0/24"]
  private_subnet_cidrs = ["10.0.11.0/24", "10.0.12.0/24"]
  availability_zones   = ["ap-northeast-1a", "ap-northeast-1c"]
}

# EC2モジュールの設定（踏み台サーバー）
ec2 = {
  public_bastion = {
    instance_type     = "t3.micro"
    ssh_key_name      = "bastion-key"
    allowed_ssh_cidrs = ["0.0.0.0/0"]
  }
}
