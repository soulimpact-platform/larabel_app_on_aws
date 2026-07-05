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
