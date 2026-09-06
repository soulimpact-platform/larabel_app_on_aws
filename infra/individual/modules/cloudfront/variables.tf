variable "project" {
  description = "Project name"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "dns" {
  description = "公開ドメインの設定（ホストゾーンは既存のものを参照する）"
  type = object({
    zone_name   = string # 例: sukunahikona.org
    record_name = string # 例: partner-admin（zone_nameと連結してFQDNになる）
  })
}

variable "origin_domain_name" {
  description = <<-EOT
    オリジン(ALB)のドメイン名。

    ALBの生DNS名(*.elb.amazonaws.com)ではなく、ACM証明書が発行されている
    FQDN を渡すこと。CloudFrontはオリジンへHTTPSで接続する際に証明書を
    検証するため、生DNS名だと名前が一致せず接続に失敗する。
  EOT
  type        = string
}

variable "web_acl_arn" {
  description = <<-EOT
    アタッチするWeb ACLのARN（CLOUDFRONTスコープ / us-east-1）。

    空文字ならアタッチしない。ALB側のWeb ACLとは役割が異なり、
    こちらは閲覧者の実IPで判定するルールだけを持つ。
  EOT
  type        = string
  default     = ""
}

variable "origin_verify_header_value" {
  description = <<-EOT
    CloudFrontがオリジンへ付与する秘密ヘッダの値。

    ALBのリスナールールが同じ値を検証し、CloudFront経由でない
    /partner/* へのアクセスを拒否する。SSMから取得した値を渡す。
  EOT
  type        = string
  sensitive   = true
}

# 既定値はここが唯一の置き場。呼び出し側は変えたい項目だけを書く。
variable "cloudfront" {
  description = "CloudFront configuration"
  type = object({
    # 価格クラス。PriceClass_200 は北米・欧州・アジアをカバーする。
    # 日本国内向けなら 100 では不足する（100 は北米・欧州のみ）
    price_class = optional(string, "PriceClass_200")

    # オリジンとの通信で許可する最小TLSバージョン
    origin_ssl_protocols = optional(list(string), ["TLSv1.2"])

    # 閲覧者との通信で許可する最小TLSバージョン
    minimum_protocol_version = optional(string, "TLSv1.2_2021")

    # アクセスログ。閲覧者の実IPが記録される唯一の経路
    access_logs_enabled        = optional(bool, true)
    access_logs_retention_days = optional(number, 30)
  })
  default = {}
}
