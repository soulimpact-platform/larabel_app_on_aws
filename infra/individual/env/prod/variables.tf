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
  description = "ECR repositories（キーがリポジトリ名の接尾辞になる）"
  type = map(object({
    image_tag_mutability = string
    keep_image_count     = number
    force_delete         = bool
  }))
}

variable "github" {
  description = "GitHub Actions role configuration"
  type = object({
    role_name        = string
    allowed_subjects = list(string)
  })
}

variable "dns" {
  description = "公開ドメインの設定（ホストゾーンは既存のものを参照する）"
  type = object({
    zone_name   = string
    record_name = string
  })
}

variable "alb" {
  description = "ALB configuration"
  type = object({
    allowed_cidrs              = list(string)
    target_port                = number
    health_check_path          = string
    deregistration_delay       = number
    idle_timeout               = number
    enable_deletion_protection = bool
    ssl_policy                 = string
  })
}

variable "ecs" {
  description = "ECS configuration"
  type = object({
    container_name        = string
    nginx_container_name  = string
    log_retention_in_days = number
    assign_public_ip      = bool

    migrate = object({
      cpu    = string
      memory = string
    })

    web = object({
      cpu                               = string
      memory                            = string
      desired_count                     = number
      health_check_grace_period_seconds = number
    })
  })
}
