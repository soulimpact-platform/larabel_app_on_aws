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

###############################################################################
# 以下の変数は既定値を持たない「素通し」の宣言。
#
# 既定値はモジュール側（../../modules/*/variables.tf）に1箇所だけ置く。
# ここに書かない属性は null としてモジュールへ渡り、モジュールの既定値が
# 適用される（null を明示した場合も同じ挙動になることを検証済み）。
#
# こうすることで env/stg を追加しても既定値が複製されず、値がズレない。
# tfvarsには「既定から意図的に外した値」だけが残る。
###############################################################################

variable "ecr" {
  description = "ECR repositories（キーがリポジトリ名の接尾辞になる）"
  type = map(object({
    image_tag_mutability = optional(string)
    keep_image_count     = optional(number)
    force_delete         = optional(bool)
  }))
  default = {}
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
    allowed_cidrs              = optional(list(string))
    target_port                = optional(number)
    health_check_path          = optional(string)
    deregistration_delay       = optional(number)
    idle_timeout               = optional(number)
    enable_deletion_protection = optional(bool)
    ssl_policy                 = optional(string)
  })
  default = {}
}

variable "monitoring" {
  description = "CloudWatchアラームの閾値設定"
  type = object({
    alb = optional(object({
      target_5xx_threshold    = optional(number)
      response_time_threshold = optional(number)
    }))
  })
  default = {}
}

variable "ecs" {
  description = "ECS configuration"
  type = object({
    container_name        = optional(string)
    nginx_container_name  = optional(string)
    log_retention_in_days = optional(number)
    assign_public_ip      = optional(bool)

    migrate = optional(object({
      cpu    = optional(string)
      memory = optional(string)
    }))

    web = optional(object({
      cpu                               = optional(string)
      memory                            = optional(string)
      desired_count                     = optional(number)
      health_check_grace_period_seconds = optional(number)
    }))
  })
  default = {}
}
