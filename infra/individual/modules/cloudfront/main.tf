###############################################################################
# パートナー向けの公開経路（CloudFront）
#
#   社内   alb-larabel.sukunahikona.org      → ALB直接（WAFのIP制限あり）
#   社外   partner-admin.sukunahikona.org    → CloudFront → ALB
#
# CloudFrontはオリジンへのリクエストに秘密ヘッダを付与する。ALBの
# リスナールールがこれを検証し、CloudFrontを経由しない /partner/* への
# アクセスを403で拒否する。
#
# Hostヘッダによる判定にしない理由: HostヘッダはクライアントがCLIから
# 自由に詐称できるため、「自分のCloudFrontから来た」ことを証明できない。
# 送信元IPも、CloudFrontのIP帯が全AWS利用者で共用のため区別できない。
###############################################################################

terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      # ACM証明書とCloudFrontはus-east-1に置く必要があるため、
      # 既定のプロバイダ(ap-northeast-1)とは別に受け取る
      configuration_aliases = [aws.us_east_1]
    }
  }
}

locals {
  name = "${var.project}-${var.environment}"
  fqdn = "${var.dns.record_name}.${var.dns.zone_name}"
}

data "aws_route53_zone" "this" {
  name         = var.dns.zone_name
  private_zone = false
}

###############################################################################
# ACM証明書
#
# CloudFrontが使える証明書はus-east-1のものだけ。ALB用(ap-northeast-1)とは
# 別リージョンに、別の証明書として発行する。
###############################################################################
resource "aws_acm_certificate" "this" {
  provider = aws.us_east_1

  domain_name       = local.fqdn
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Name = local.fqdn
  }
}

# 検証用レコードはホストゾーンのあるアカウント側（=既定プロバイダ）に作る。
# Route53はグローバルサービスなのでリージョンを問わない
resource "aws_route53_record" "certificate_validation" {
  for_each = {
    for dvo in aws_acm_certificate.this.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      type   = dvo.resource_record_type
      record = dvo.resource_record_value
    }
  }

  zone_id         = data.aws_route53_zone.this.zone_id
  name            = each.value.name
  type            = each.value.type
  records         = [each.value.record]
  ttl             = 60
  allow_overwrite = true
}

resource "aws_acm_certificate_validation" "this" {
  provider = aws.us_east_1

  certificate_arn         = aws_acm_certificate.this.arn
  validation_record_fqdns = [for r in aws_route53_record.certificate_validation : r.fqdn]
}

###############################################################################
# キャッシュ/転送ポリシー（AWSマネージド）
#
# 認証付きアプリなのでキャッシュは全面的に無効化する。有効にすると
# 他人のセッションでレンダリングされたページが配信される事故になる。
#
# AllViewer は Cookie・クエリ文字列・ヘッダをすべてオリジンへ転送する。
# これが無いとセッションもCSRFトークンも通らない。Hostヘッダも転送されるため、
# Laravelは partner-admin.sukunahikona.org でURLを生成する
# （trustProxies(at: '*') 設定済みのため）。
###############################################################################
data "aws_cloudfront_cache_policy" "caching_disabled" {
  name = "Managed-CachingDisabled"
}

data "aws_cloudfront_origin_request_policy" "all_viewer" {
  name = "Managed-AllViewer"
}

###############################################################################
# ディストリビューション
###############################################################################
resource "aws_cloudfront_distribution" "this" {
  enabled         = true
  is_ipv6_enabled = true
  comment         = "${local.name} partner portal"
  price_class     = var.cloudfront.price_class

  aliases = [local.fqdn]

  origin {
    origin_id   = "alb"
    domain_name = var.origin_domain_name

    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "https-only"
      origin_ssl_protocols   = var.cloudfront.origin_ssl_protocols
    }

    # ALBのリスナールールが検証する秘密ヘッダ。
    # インターネット側からは見えず、閲覧者が書き換えることもできない
    custom_header {
      name  = "X-Origin-Verify"
      value = var.origin_verify_header_value
    }
  }

  default_cache_behavior {
    target_origin_id       = "alb"
    viewer_protocol_policy = "redirect-to-https"

    # フォーム送信があるため全メソッドを通す
    allowed_methods = ["GET", "HEAD", "OPTIONS", "PUT", "POST", "PATCH", "DELETE"]
    cached_methods  = ["GET", "HEAD"]

    cache_policy_id          = data.aws_cloudfront_cache_policy.caching_disabled.id
    origin_request_policy_id = data.aws_cloudfront_origin_request_policy.all_viewer.id

    compress = true
  }

  # 地域制限は設けない。パートナーの所在地を限定できないため
  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    acm_certificate_arn      = aws_acm_certificate_validation.this.certificate_arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = var.cloudfront.minimum_protocol_version
  }

  tags = {
    Name = local.fqdn
  }
}

###############################################################################
# Route53 Aliasレコード
###############################################################################
resource "aws_route53_record" "this" {
  # IPv4とIPv6の両方を向ける
  for_each = toset(["A", "AAAA"])

  zone_id = data.aws_route53_zone.this.zone_id
  name    = local.fqdn
  type    = each.value

  alias {
    name    = aws_cloudfront_distribution.this.domain_name
    zone_id = aws_cloudfront_distribution.this.hosted_zone_id
    # CloudFrontはヘルスチェックに対応しないため false 固定
    evaluate_target_health = false
  }
}
