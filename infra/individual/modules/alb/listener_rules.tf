###############################################################################
# リスナールール（CloudFront経由の識別）
#
# 優先度の小さいものから評価され、最初に一致したルールが適用される。
#
#   10  CF経由 かつ パートナー領域/静的アセット → 転送     社外の正規経路
#   20  パートナー領域（ヘッダ無し）            → 403      ALB直叩きを拒否
#   30  CF経由（上記以外のパス）                → 403      CF経由での /admin/* 迂回を拒否
#   既定 それ以外                                → 転送     社内の直接アクセス
#
# 守っているのは X-Origin-Verify ヘッダのみ。Hostヘッダは条件に含めるが
# クライアントが詐称できるため、認可の根拠にはならない。
###############################################################################

locals {
  # 秘密値が未設定のあいだはルールを作らない（CloudFront導入前の状態）
  cloudfront_enabled = var.cloudfront.origin_verify_header_value != ""

  # CF経由で到達してよいパス。ALBのパス条件は1条件あたり最大5個
  cloudfront_allowed_paths = concat(
    var.cloudfront.partner_path_patterns,
    var.cloudfront.shared_asset_path_patterns,
  )
}

# ① CloudFront経由のパートナー領域 → 転送
resource "aws_lb_listener_rule" "partner_via_cloudfront" {
  count = local.cloudfront_enabled ? 1 : 0

  listener_arn = aws_lb_listener.https.arn
  priority     = 10

  condition {
    path_pattern {
      values = local.cloudfront_allowed_paths
    }
  }

  condition {
    http_header {
      http_header_name = "X-Origin-Verify"
      values           = [var.cloudfront.origin_verify_header_value]
    }
  }

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.this.arn
  }

  tags = {
    Name = "${var.project}-${var.environment}-partner-via-cloudfront"
  }
}

# ② CloudFrontを経由しないパートナー領域 → 403
resource "aws_lb_listener_rule" "partner_direct_denied" {
  count = local.cloudfront_enabled ? 1 : 0

  listener_arn = aws_lb_listener.https.arn
  priority     = 20

  condition {
    path_pattern {
      values = var.cloudfront.partner_path_patterns
    }
  }

  action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      status_code  = "403"
      message_body = "Forbidden: this path is only reachable through the partner portal."
    }
  }

  tags = {
    Name = "${var.project}-${var.environment}-partner-direct-denied"
  }
}

# ③ CloudFront経由で社内領域へ迂回しようとしたもの → 403
#
# これが無いと partner-admin ドメイン経由で /admin/* に到達でき、
# WAFのIP制限を迂回する経路になる（CloudFrontのIPは許可IPではないため
# 実際にはWAF側でも止まるが、意図を明示して二重に塞ぐ）
resource "aws_lb_listener_rule" "cloudfront_scope_limited" {
  count = local.cloudfront_enabled ? 1 : 0

  listener_arn = aws_lb_listener.https.arn
  priority     = 30

  condition {
    http_header {
      http_header_name = "X-Origin-Verify"
      values           = [var.cloudfront.origin_verify_header_value]
    }
  }

  action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      status_code  = "403"
      message_body = "Forbidden: the partner portal serves partner paths only."
    }
  }

  tags = {
    Name = "${var.project}-${var.environment}-cloudfront-scope-limited"
  }
}
