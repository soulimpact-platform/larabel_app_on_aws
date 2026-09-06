variable "project" {
  description = "Project name"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "alert_topic_arn" {
  description = "通知先のSNSトピックARN（common側で作成したもの）"
  type        = string
}

variable "alb" {
  description = "監視対象ALBの識別子。ARNではなくarn_suffixを渡すこと"
  type = object({
    arn_suffix              = string
    target_group_arn_suffix = string
  })
}

# 既定値はここが唯一の置き場。呼び出し側は変えたい項目だけを書く。
variable "monitoring" {
  description = "アラームの閾値設定"
  type = object({
    alb = optional(object({
      # 5分間にこの件数以上の5XXが出たら通知
      target_5xx_threshold = optional(number, 5)
      # p95レスポンスタイムの上限（秒）
      response_time_threshold = optional(number, 3)
    }), {})
  })
  default = {}
}
