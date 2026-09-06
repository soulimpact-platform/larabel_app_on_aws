###############################################################################
# CloudFront用のWeb ACL（scope = CLOUDFRONT / us-east-1）
#
# 送信元IPで判定するルールだけをここに置く。
#
# ALB側のWeb ACLから見ると、CloudFront経由の通信は送信元がCloudFrontの
# IPになる。そのため次の2つが正しく機能しない。
#   - IPレピュテーション: CloudFrontのIPは当然クリーンで永久にマッチしない
#   - レート制限        : 全パートナーが同一IPに合算される
#
# X-Forwarded-For を見る回避策もあるが、
#   - WAFはXFFの先頭のIPを評価する
#   - CloudFrontは閲覧者が送ったXFFの後ろに実IPを追記する
# ため、閲覧者が任意の値を先頭に置けば判定を迂回できる。
# マネージドルールに至ってはXFFを参照する設定自体が無い。
#
# 詐称不可能な実IPで評価するには、CloudFront側で見るしかない。
#
# 内容を見るルール（SQLi/XSS/PHP等）はALB側に置いたままにする。
# 送信元が誰に見えても判定できるため、両方に置くと重複するうえ
# COUNT→BLOCKの調整箇所が2倍になる。
###############################################################################

terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      # CLOUDFRONTスコープのWeb ACLはus-east-1にしか作れない
      configuration_aliases = [aws.us_east_1]
    }
  }
}

locals {
  name = "${var.project}-${var.environment}-cf"

  managed_rule_groups = {
    for idx, group_name in var.waf_cloudfront.managed_rule_groups : group_name => idx + 10
  }
}

resource "aws_wafv2_web_acl" "this" {
  provider = aws.us_east_1

  name        = "${local.name}-waf"
  description = "Web ACL for ${var.project}-${var.environment} CloudFront"
  scope       = "CLOUDFRONT"

  # 既定は通す。ここで止めるのは「送信元IPが悪い」場合のみ
  default_action {
    allow {}
  }

  dynamic "rule" {
    for_each = local.managed_rule_groups

    content {
      name     = rule.key
      priority = rule.value

      override_action {
        dynamic "count" {
          for_each = var.waf_cloudfront.count_only ? [1] : []
          content {}
        }
        dynamic "none" {
          for_each = var.waf_cloudfront.count_only ? [] : [1]
          content {}
        }
      }

      statement {
        managed_rule_group_statement {
          vendor_name = "AWS"
          name        = rule.key
        }
      }

      visibility_config {
        cloudwatch_metrics_enabled = true
        metric_name                = rule.key
        sampled_requests_enabled   = true
      }
    }
  }

  # レート制限。ここでは閲覧者の実IPで集計されるため、
  # 個別のブルートフォースを正しく検知できる
  rule {
    name     = "rate-limit"
    priority = 100

    action {
      dynamic "count" {
        for_each = var.waf_cloudfront.count_only ? [1] : []
        content {}
      }
      dynamic "block" {
        for_each = var.waf_cloudfront.count_only ? [] : [1]
        content {}
      }
    }

    statement {
      rate_based_statement {
        limit              = var.waf_cloudfront.rate_limit
        aggregate_key_type = "IP"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "rate-limit"
      sampled_requests_enabled   = true
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "${local.name}-waf"
    sampled_requests_enabled   = true
  }

  tags = {
    Name = "${local.name}-waf"
  }
}

###############################################################################
# WAFログ
#
# CLOUDFRONTスコープのログはus-east-1にしか置けない。
# ALB側と違い httpRequest.clientIp がそのまま閲覧者の実IPになる
###############################################################################
resource "aws_cloudwatch_log_group" "waf" {
  provider = aws.us_east_1

  # 名前は "aws-waf-logs-" で始まる必要がある（WAFの仕様）
  name              = "aws-waf-logs-${local.name}"
  retention_in_days = var.waf_cloudfront.log_retention_in_days

  tags = {
    Name = "aws-waf-logs-${local.name}"
  }
}

resource "aws_wafv2_web_acl_logging_configuration" "this" {
  provider = aws.us_east_1

  resource_arn = aws_wafv2_web_acl.this.arn

  # log_group の arn は末尾に ":*" が付くが、WAF側は受け付けない
  log_destination_configs = [trimsuffix(aws_cloudwatch_log_group.waf.arn, ":*")]

  # 認証情報とオリジン検証用の秘密値がログに残らないようにする
  redacted_fields {
    single_header {
      name = "authorization"
    }
  }

  redacted_fields {
    single_header {
      name = "cookie"
    }
  }

  dynamic "logging_filter" {
    for_each = var.waf_cloudfront.log_all_requests ? [] : [1]

    content {
      default_behavior = "DROP"

      filter {
        behavior    = "KEEP"
        requirement = "MEETS_ANY"

        # override_action = count のマネージドルールは
        # EXCLUDED_AS_COUNT として記録される
        condition {
          action_condition {
            action = "EXCLUDED_AS_COUNT"
          }
        }

        condition {
          action_condition {
            action = "COUNT"
          }
        }

        condition {
          action_condition {
            action = "BLOCK"
          }
        }
      }
    }
  }
}
