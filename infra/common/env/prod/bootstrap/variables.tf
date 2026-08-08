variable "project" {
  description = "Project name"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "region" {
  description = "AWS region"
  type        = string
}

variable "state_bucket_name" {
  description = "S3 bucket name for Terraform state"
  type        = string
}

variable "db_credentials" {
  description = "RDS database credentials (db_name / username / password)"
  type = object({
    db_name  = string
    username = string
    password = string
  })
  sensitive = true
}
