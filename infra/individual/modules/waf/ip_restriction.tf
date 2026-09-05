###############################################################################
# IP制限（ラベル方式）
#
# 「全パスを防御しつつ、特定パスだけ免除する」を素直に書くための構成。
#
#   優先度 0  mark-public-path  公開パスに印(ラベル)を付けるだけ。actionはcount
#                               → count は終端しないので評価は次へ進む
#   優先度 1  ip-restriction    許可IPでない AND 印が付いていない → block
#                               → block は終端するので、ここで止まる
#   優先度10〜 マネージドルール   通過したものだけが検査される
#
# 「防御の記述」と「例外の記述」が分離するため、パスを増やすときは
# 正規表現セットに1行足すだけで済み、ip-restriction 側は二度と触らない。
#
# なお public_path_regexes が空の場合、ラベルを付けるルールが作られないため
# どのリクエストにも印が付かず、AND条件は「許可IPでない」だけに縮退する。
###############################################################################

locals {
  ip_restriction_enabled = length(var.waf.allowed_ip_cidrs) > 0
  public_paths_enabled   = length(var.waf.public_path_regexes) > 0

  # CloudFront経由でのみ免除するパスの判定を行うか。
  # パスの列挙と秘密値の両方が揃っている場合にのみ有効になる
  cloudfront_paths_enabled = length(var.waf.cloudfront_path_regexes) > 0 && var.waf.origin_verify_header_value != ""

  # 免除対象を表す印。Web ACL直下のルールが付ける独自ラベルは
  # マネージドルールのような接頭辞が付かず、この名前のまま照合できる
  public_path_label = "public-path"
}

resource "aws_wafv2_ip_set" "allowed" {
  count = local.ip_restriction_enabled ? 1 : 0

  name = "${local.name}-allowed-ips"
  # descriptionはWAFの制約でASCIIのみ（日本語を入れるとapplyが失敗する）
  description        = "Allowed source IPs for IP restriction"
  scope              = var.waf.scope
  ip_address_version = "IPV4"
  addresses          = var.waf.allowed_ip_cidrs

  tags = {
    Name = "${local.name}-allowed-ips"
  }
}

resource "aws_wafv2_regex_pattern_set" "public_paths" {
  count = local.public_paths_enabled ? 1 : 0

  name = "${local.name}-public-paths"
  # descriptionはWAFの制約でASCIIのみ
  description = "URI paths exempt from IP restriction"
  scope       = var.waf.scope

  dynamic "regular_expression" {
    for_each = var.waf.public_path_regexes
    content {
      regex_string = regular_expression.value
    }
  }

  tags = {
    Name = "${local.name}-public-paths"
  }
}

resource "aws_wafv2_regex_pattern_set" "cloudfront_paths" {
  count = local.cloudfront_paths_enabled ? 1 : 0

  name = "${local.name}-cloudfront-paths"
  # descriptionはWAFの制約でASCIIのみ
  description = "URI paths served only through CloudFront"
  scope       = var.waf.scope

  dynamic "regular_expression" {
    for_each = var.waf.cloudfront_path_regexes
    content {
      regex_string = regular_expression.value
    }
  }

  tags = {
    Name = "${local.name}-cloudfront-paths"
  }
}
