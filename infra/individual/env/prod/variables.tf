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

variable "ecr" {
  description = "ECR repository configuration"
  type = object({
    repository_name      = string
    image_tag_mutability = string
    keep_image_count     = number
    force_delete         = bool
  })
}

variable "github" {
  description = "GitHub Actions role configuration"
  type = object({
    role_name        = string
    allowed_subjects = list(string)
  })
}

variable "ecs" {
  description = "ECS configuration"
  type = object({
    container_name        = string
    log_retention_in_days = number
    migrate = object({
      cpu    = string
      memory = string
    })
  })
}
