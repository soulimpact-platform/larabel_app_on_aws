variable "project" {
  description = "Project name"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

# 既定値はここが唯一の置き場。呼び出し側は変えたい項目だけを書く。
variable "waf_cloudfront" {
  description = "CloudFront用Web ACLの設定"
  type = object({
    # 送信元IPで判定するマネージドルール。
    # 内容を見るルール（SQLi/XSS等）はALB側で評価しており、
    # ここに置くと二重になりCOUNT→BLOCKの調整箇所も倍になる
    managed_rule_groups = optional(list(string), [
      "AWSManagedRulesAmazonIpReputationList",
    ])

    # 5分あたり同一IPからの上限リクエスト数
    rate_limit = optional(number, 2000)

    # 誤検知を洗い出すまで一切ブロックしない
    count_only = optional(bool, true)

    log_retention_in_days = optional(number, 30)
    log_all_requests      = optional(bool, false)
  })
  default = {}
}
