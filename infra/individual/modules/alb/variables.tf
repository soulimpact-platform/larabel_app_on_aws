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

variable "subnet_ids" {
  description = "ALBを配置するサブネットID（Publicサブネット。2AZ以上必須）"
  type        = list(string)
}

variable "dns" {
  description = "公開ドメインの設定（ホストゾーンは既存のものを参照する）"
  type = object({
    zone_name   = string # 例: sukunahikona.org
    record_name = string # 例: alb-larabel（zone_nameと連結してFQDNになる）
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
