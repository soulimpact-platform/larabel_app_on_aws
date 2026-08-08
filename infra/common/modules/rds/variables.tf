variable "project" {
  description = "Project name"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID to place the RDS instance in"
  type        = string
}

variable "subnet_ids" {
  description = "Subnet IDs for the DB subnet group (private subnets, 2AZ以上)"
  type        = list(string)
}

variable "allowed_security_group_ids" {
  description = "Security group IDs allowed to connect to the RDS instance"
  type        = list(string)
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
    # SSM上のパスワードを変更したときに増やす。値が変わったときだけDBへ反映される
    password_version = number
  })
}
