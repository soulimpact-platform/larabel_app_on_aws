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

# 既定値はここが唯一の置き場。呼び出し側は変えたい項目だけを書く。
# 属性を省略した場合も null を明示した場合も、ここの既定値が適用される。
variable "ecs" {
  description = "ECS configuration"
  type = object({
    container_name        = optional(string, "app")
    nginx_container_name  = optional(string, "nginx")
    log_retention_in_days = optional(number, 30)
    # Privateサブネットに配置しNAT Gateway経由で外へ出るためfalse
    assign_public_ip = optional(bool, false)

    migrate = optional(object({
      cpu    = optional(string, "512")  # 0.5 vCPU
      memory = optional(string, "1024") # 1GB
    }), {})

    web = optional(object({
      cpu    = optional(string, "512")  # 0.5 vCPU（nginx + php-fpm の合計）
      memory = optional(string, "1024") # 1GB
      # 既定は2。可用性のため冗長化する側を既定にする
      desired_count = optional(number, 2)
      # ALBのヘルスチェックが通るまでの猶予。Laravelの初回起動を待つ
      health_check_grace_period_seconds = optional(number, 60)
    }), {})
  })
  default = {}
}
