###############################################################################
# WAF (Web ACL)
#
# セキュリティグループが「誰が・どのポートに」で止めるのに対し、WAFは
# リクエストの中身（URI・ヘッダ・ボディ）を検査して止める。
# SQLインジェクションやパストラバーサルはSGでは防げない。
#
# ファイル構成:
#   main.tf     Web ACL本体とALBへの関連付け
#   logging.tf  ログ出力先の設定
#
# 現在は count_only = true で運用する。マネージドルールは正常な通信を
# 誤って落とすことがあり（LaravelのフォームPOSTがXSS判定される等）、
# いきなりBLOCKにすると原因不明の障害になるため。
###############################################################################

locals {
  name = "${var.project}-${var.environment}"

  # リストの並び順をそのまま優先度にする。
  # 0-1番はIP制限（ip_restriction.tf）に予約、マネージドルールは10番から、
  # レートベースは100番に置いて間隔を空けておく
  managed_rule_groups = {
    for idx, group_name in var.waf.managed_rule_groups : group_name => idx + 10
  }
}

resource "aws_wafv2_web_acl" "this" {
  name        = "${local.name}-waf"
  description = "Web ACL for ${local.name}"
  scope       = var.waf.scope

  # 既定は通す。WAFは「怪しいものだけ落とす」ブラックリスト運用にする。
  # blockを既定にすると、ルールに書き漏れた正常な通信まで全て落ちる
  default_action {
    allow {}
  }

  #############################################################################
  # IP制限（詳細は ip_restriction.tf のコメントを参照）
  #############################################################################

  # 優先度0: 公開パスに印を付けるだけ。count は終端しないので評価は続く
  dynamic "rule" {
    for_each = local.public_paths_enabled ? [1] : []

    content {
      name     = "mark-public-path"
      priority = 0

      action {
        count {}
      }

      rule_label {
        name = local.public_path_label
      }

      statement {
        regex_pattern_set_reference_statement {
          arn = aws_wafv2_regex_pattern_set.public_paths[0].arn

          field_to_match {
            uri_path {}
          }

          # 大文字小文字を無視して照合する
          text_transformation {
            priority = 0
            type     = "LOWERCASE"
          }
        }
      }

      visibility_config {
        cloudwatch_metrics_enabled = true
        metric_name                = "mark-public-path"
        sampled_requests_enabled   = true
      }
    }
  }

  # 優先度1: CloudFront経由の正規リクエストに印を付ける。
  #
  # 秘密ヘッダとパスの両方が一致した場合のみラベルを付ける。
  # ALBのリスナールールと同じ判定を重ねることで、
  #   - ALB直叩きの試行がWAFログに残る（リスナールールの403は記録されない）
  #   - リスナールールが壊れてもIP制限が働く
  # という2点を得る。値はTerraformが同じSSMから配るため手動同期は不要
  dynamic "rule" {
    for_each = local.cloudfront_paths_enabled ? [1] : []

    content {
      name     = "mark-cloudfront-origin"
      priority = 1

      action {
        count {}
      }

      rule_label {
        name = local.public_path_label
      }

      statement {
        and_statement {
          # 条件1: CloudFrontが付与する秘密ヘッダが一致する
          statement {
            byte_match_statement {
              search_string         = var.waf.origin_verify_header_value
              positional_constraint = "EXACTLY"

              field_to_match {
                single_header {
                  name = "x-origin-verify"
                }
              }

              text_transformation {
                priority = 0
                type     = "NONE"
              }
            }
          }

          # 条件2: CloudFrontが配信すべきパスである。
          # これが無いとCF経由で /admin/* に到達できてしまう
          statement {
            regex_pattern_set_reference_statement {
              arn = aws_wafv2_regex_pattern_set.cloudfront_paths[0].arn

              field_to_match {
                uri_path {}
              }

              text_transformation {
                priority = 0
                type     = "LOWERCASE"
              }
            }
          }
        }
      }

      visibility_config {
        cloudwatch_metrics_enabled = true
        metric_name                = "mark-cloudfront-origin"
        sampled_requests_enabled   = true
      }
    }
  }

  # 優先度1: 許可IPでなく、かつ印も付いていないものを遮断する。
  # block は終端するため、以降のマネージドルールは評価されない
  dynamic "rule" {
    for_each = local.ip_restriction_enabled ? [1] : []

    content {
      name     = "ip-restriction"
      priority = 2

      action {
        block {}
      }

      statement {
        and_statement {
          # 条件1: 許可IPリストに含まれない
          statement {
            not_statement {
              statement {
                ip_set_reference_statement {
                  arn = aws_wafv2_ip_set.allowed[0].arn
                }
              }
            }
          }

          # 条件2: 公開パスの印が付いていない。
          # 印を付けるルールが無い場合はどのリクエストにも付かないため、
          # この条件は常に真となりIP判定のみに縮退する
          statement {
            not_statement {
              statement {
                label_match_statement {
                  scope = "LABEL"
                  key   = local.public_path_label
                }
              }
            }
          }
        }
      }

      visibility_config {
        cloudwatch_metrics_enabled = true
        metric_name                = "ip-restriction"
        sampled_requests_enabled   = true
      }
    }
  }

  #############################################################################
  # AWSマネージドルールグループ
  #############################################################################
  dynamic "rule" {
    for_each = local.managed_rule_groups

    content {
      name     = rule.key
      priority = rule.value

      # マネージドルールグループでは action ではなく override_action を使う。
      #   count : グループ内の全ルールを「記録のみ」に落とす
      #   none  : グループが定義したアクション（多くはBLOCK）で動かす
      override_action {
        dynamic "count" {
          for_each = var.waf.count_only ? [1] : []
          content {}
        }
        dynamic "none" {
          for_each = var.waf.count_only ? [] : [1]
          content {}
        }
      }

      statement {
        managed_rule_group_statement {
          vendor_name = "AWS"
          name        = rule.key
        }
      }

      # ルール単位でメトリクスを出す。これが無いと
      # 「どのルールが何件マッチしたか」が分からずCOUNTモードの意味が消える
      visibility_config {
        cloudwatch_metrics_enabled = true
        metric_name                = rule.key
        sampled_requests_enabled   = true
      }
    }
  }

  #############################################################################
  # レートベース制限（自作ルール）
  #
  # 自作ルールは override_action ではなく action を使う。
  # マネージドルールグループとは指定方法が異なる点に注意
  #############################################################################
  rule {
    name     = "rate-limit"
    priority = 100

    action {
      dynamic "count" {
        for_each = var.waf.count_only ? [1] : []
        content {}
      }
      dynamic "block" {
        for_each = var.waf.count_only ? [] : [1]
        content {}
      }
    }

    statement {
      rate_based_statement {
        limit              = var.waf.rate_limit
        aggregate_key_type = "IP"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "rate-limit"
      sampled_requests_enabled   = true
    }
  }

  # Web ACL全体のメトリクス
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
# ALBへの関連付け
#
# この関連付けはREGIONALスコープでのみ可能。CLOUDFRONTスコープの場合は
# CloudFrontディストリビューション側で web_acl_id を指定する形になるため、
# ここでは作らない
###############################################################################
resource "aws_wafv2_web_acl_association" "alb" {
  count = var.waf.scope == "REGIONAL" ? 1 : 0

  resource_arn = var.alb_arn
  web_acl_arn  = aws_wafv2_web_acl.this.arn
}
