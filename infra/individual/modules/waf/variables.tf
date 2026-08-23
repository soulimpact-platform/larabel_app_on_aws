variable "project" {
  description = "Project name"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "alb_arn" {
  description = "Web ACLを関連付けるALBのARN（arn_suffixではなくARN全体）"
  type        = string
}

# 既定値はここが唯一の置き場。呼び出し側は変えたい項目だけを書く。
variable "waf" {
  description = "WAF configuration"
  type = object({
    # REGIONAL: ALB/API Gateway用（Web ACLと同一リージョン）
    # CLOUDFRONT: CloudFront用（us-east-1にしか作れない）
    # 両者は相互に変更できず、切り替えるとWeb ACLの作り直しになる
    scope = optional(string, "REGIONAL")

    # trueの間は一切ブロックせず、マッチした事実だけを記録する。
    # 誤検知を洗い出してからfalseにする運用を想定
    count_only = optional(bool, true)

    # AWSマネージドルールグループ。リストの順序がそのまま優先度になる。
    #
    # WCU（ルールの計算コスト）上限は既定で1500。内訳は
    #   Common 700 / KnownBadInputs 200 / SQLi 200 / PHP 100 / IpReputation 25
    #   + 下のレートベース 2 = 合計1227
    # 追加する場合は上限超過に注意（超えるとapplyが失敗する）
    managed_rule_groups = optional(list(string), [
      "AWSManagedRulesCommonRuleSet",
      "AWSManagedRulesKnownBadInputsRuleSet",
      "AWSManagedRulesSQLiRuleSet",
      "AWSManagedRulesPHPRuleSet",
      "AWSManagedRulesAmazonIpReputationList",
    ])

    # 5分あたり同一IPからの上限リクエスト数。
    # 将来CloudFrontを前段に置くとCloudFrontのIPしか見えなくなり
    # このルールは機能しなくなる（その時はCLOUDFRONTスコープ側へ移す）
    rate_limit = optional(number, 2000)

    # IP制限。空のままならIP制限ルール自体を作らない（従来どおり全開放）。
    # 値を入れた瞬間に、ここに無いIPからのアクセスはブロックされる。
    # count_only とは独立に効く（様子見中でもIP制限だけは実際に遮断する）
    allowed_ip_cidrs = optional(list(string), [])

    # IP制限を免除するパスの正規表現。allowed_ip_cidrs が空なら無関係。
    # ヘルスチェックや静的アセットなど、誰からでも到達させたいものを列挙する
    public_path_regexes = optional(list(string), [])

    # ログの保持日数
    log_retention_in_days = optional(number, 30)

    # false: ルールにマッチしたリクエストだけを記録する（既定・低コスト）
    # true : 全リクエストを記録する。誤検知率の分母が欲しい場合に使う
    log_all_requests = optional(bool, false)
  })
  default = {}
}
