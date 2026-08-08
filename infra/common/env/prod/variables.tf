variable "project" {
  description = "Project name"
  type        = string
}

variable "environment" {
  description = "Environment name (e.g. prod, stg, dev)"
  type        = string
}

variable "region" {
  description = "AWS region"
  type        = string
}

variable "vpc" {
  description = "VPC configuration"
  type = object({
    cidr                 = string
    public_subnet_cidrs  = list(string)
    private_subnet_cidrs = list(string)
    availability_zones   = list(string)
  })
}

variable "ec2" {
  description = "EC2 instances configuration"
  type = object({
    public_bastion = object({
      instance_type     = string
      ssh_key_name      = string
      allowed_ssh_cidrs = list(string)
    })
  })
}

variable "rds" {
  description = "RDS instance configuration"
  type = object({
    engine_version                  = string
    parameter_group_family          = string
    instance_class                  = string
    allocated_storage               = number
    max_allocated_storage           = number
    port                            = number
    multi_az                        = bool
    backup_retention_period         = number
    backup_window                   = string
    maintenance_window              = string
    deletion_protection             = bool
    skip_final_snapshot             = bool
    enabled_cloudwatch_logs_exports = list(string)
    password_version                = number
  })
}
