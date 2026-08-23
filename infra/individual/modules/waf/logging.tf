###############################################################################
# WAFログ
#
# CloudWatchメトリクスは「何件マッチしたか」しか分からない。
# 「どのIPが・どのURIに・どんなリクエストを投げたのか」を知るにはログが要る。
#
# COUNTモードで特に重要なのがログ中の nonTerminatingMatchingRules で、
# 「ブロックはしていないがマッチした」ルールがここに記録される。
# BLOCKへ切り替えた場合に何が落ちるかを、事前に正確に見積もれる。
###############################################################################

resource "aws_cloudwatch_log_group" "waf" {
  # 名前は "aws-waf-logs-" で始まる必要がある（WAFの仕様）。
  # 他の名前を付けるとログ設定のapplyが失敗する
  name              = "aws-waf-logs-${local.name}"
  retention_in_days = var.waf.log_retention_in_days

  tags = {
    Name = "aws-waf-logs-${local.name}"
  }
}

resource "aws_wafv2_web_acl_logging_configuration" "this" {
  resource_arn = aws_wafv2_web_acl.this.arn

  # aws_cloudwatch_log_group の arn は末尾に ":*" が付くが、
  # WAF側はこれを受け付けないため取り除く
  log_destination_configs = [trimsuffix(aws_cloudwatch_log_group.waf.arn, ":*")]

  # 認証情報がログに残らないようにする。
  # WAFログはリクエストヘッダをそのまま記録するため、
  # 無指定だとセッションCookieやBearerトークンが平文で保存される
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

  # CloudFrontがオリジンへ付与する秘密ヘッダ。
  # WAFログは httpRequest.headers をそのまま記録するため、
  # マスクしないと秘密値がCloudWatch Logsに平文で残る
  redacted_fields {
    single_header {
      name = "x-origin-verify"
    }
  }

  # 既定ではルールにマッチしたリクエストだけを残す。
  # 全リクエストを記録すると、調査に使わない正常系のログで
  # 取込料が膨らむため。誤検知率の分母はCloudWatchメトリクス側で取れる
  dynamic "logging_filter" {
    for_each = var.waf.log_all_requests ? [] : [1]

    content {
      default_behavior = "DROP"

      filter {
        behavior    = "KEEP"
        requirement = "MEETS_ANY"

        # override_action = count にしたマネージドルールのマッチは
        # COUNT ではなく EXCLUDED_AS_COUNT として記録される。
        # これを入れ忘れるとCOUNTモード中のログが1件も残らない
        condition {
          action_condition {
            action = "EXCLUDED_AS_COUNT"
          }
        }

        # 自作ルール（レートベース）をcountにした場合はこちら
        condition {
          action_condition {
            action = "COUNT"
          }
        }

        # BLOCKへ切り替えた後に効く
        condition {
          action_condition {
            action = "BLOCK"
          }
        }
      }
    }
  }
}
