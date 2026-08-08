###############################################################################
# Modules
###############################################################################
module "vpc" {
  source = "../../modules/vpc"

  project     = var.project
  environment = var.environment
  vpc         = var.vpc
}

module "ec2" {
  source = "../../modules/ec2"

  project          = var.project
  environment      = var.environment
  vpc_id           = module.vpc.vpc_id
  public_subnet_id = module.vpc.public_subnet_ids[0]
  ec2              = var.ec2
}

module "rds" {
  source = "../../modules/rds"

  project     = var.project
  environment = var.environment

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnet_ids

  # 現状は踏み台からのみ接続を許可。ECS導入後はそのSGもここに追加する
  allowed_security_group_ids = [module.ec2.bastion_security_group_id]

  rds = var.rds
}

# GitHub ActionsのOIDCプロバイダ。アカウントに1つだけ作れる土台のため
# common側で管理する。これを引き受けるロールは infra/individual 側で定義する
module "github_oidc" {
  source = "../../modules/github_oidc"

  project     = var.project
  environment = var.environment
}
