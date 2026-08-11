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

# 既定値はここが唯一の置き場。呼び出し側は変えたい項目だけを書く。
# 属性を省略した場合も null を明示した場合も、ここの既定値が適用される。
variable "alb" {
  description = "ALB configuration"
  type = object({
    allowed_cidrs = optional(list(string), ["0.0.0.0/0"])
    target_port   = optional(number, 80)
    # Laravelが標準で用意するヘルスチェック経路
    health_check_path = optional(string, "/up")
    # デプロイ時の切り替えを速くするため短めにする
    deregistration_delay = optional(number, 30)
    idle_timeout         = optional(number, 60)
    ssl_policy           = optional(string, "ELBSecurityPolicy-TLS13-1-2-2021-06")
    # 既定は安全側。検証環境で外したい場合のみtfvarsで明示的にfalseにする
    enable_deletion_protection = optional(bool, true)
  })
  default = {}
}
