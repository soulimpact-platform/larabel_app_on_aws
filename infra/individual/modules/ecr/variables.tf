variable "project" {
  description = "Project name"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "ecr" {
  description = "ECR repository configuration"
  type = object({
    repository_name      = string
    image_tag_mutability = string # MUTABLE or IMMUTABLE
    keep_image_count     = number
    force_delete         = bool
  })
}
