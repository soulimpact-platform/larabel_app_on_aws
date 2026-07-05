variable "project" {
  description = "Project name"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID to place the bastion host in"
  type        = string
}

variable "public_subnet_id" {
  description = "Public subnet ID to place the bastion host in"
  type        = string
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
