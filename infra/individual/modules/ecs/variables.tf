variable "project" {
  description = "Project name"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "ecr_repository_url" {
  description = "アプリケーションイメージのECRリポジトリURL"
  type        = string
}

variable "subnet_ids" {
  description = "ECSタスクを配置するサブネットID（Privateサブネット）"
  type        = list(string)
}

variable "security_group_ids" {
  description = "ECSタスクに付与するSG（RDSクライアントSGを含める）"
  type        = list(string)
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
    log_retention_in_days = number
    migrate = object({
      cpu    = string
      memory = string
    })
  })
}
