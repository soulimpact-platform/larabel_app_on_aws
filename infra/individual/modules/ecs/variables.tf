variable "project" {
  description = "Project name"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "ecr_repository_urls" {
  description = "コンテナごとのECRリポジトリURL（キー: app / nginx）"
  type = object({
    app   = string
    nginx = string
  })
}

variable "subnet_ids" {
  description = "ECSタスクを配置するサブネットID"
  type        = list(string)
}

variable "security_group_ids" {
  description = "migrateタスクに付与するSG（RDSクライアントSGを含める）"
  type        = list(string)
}

variable "additional_security_group_ids" {
  description = "Webタスクに追加で付与するSG（RDSクライアントSGなど）"
  type        = list(string)
}

variable "alb" {
  description = "ALBとの接続情報"
  type = object({
    security_group_id = string
    target_group_arn  = string
  })
}

variable "app_url" {
  description = "アプリケーションの公開URL（Laravelのリンク生成に使う）"
  type        = string
}

variable "db" {
  description = "接続先RDSの情報（認証情報はSSMから取得するためここには含めない）"
  type = object({
    host = string
    port = number
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
