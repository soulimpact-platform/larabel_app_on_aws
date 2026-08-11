###############################################################################
# アラート通知用のSNSトピック
#
# CloudWatchアラームはメールを直接送る機能を持たない。実行できるアクションは
# 実質SNSへの発行だけなので、通知経路には必ずトピックが必要になる。
#
# ただしこれは制約というより利点で、トピックを分配点にしておけば
# 通知先（メール、将来のSlack、Lambda）を増やしてもアラーム側の定義は
# 一切変更しなくてよい。
#
# individual側ではなくcommonに置いている理由:
#   メール購読の確認は人が一度リンクをクリックする必要がある。
#   individualはアプリごと破棄されうるため、そこにトピックを置くと
#   破棄・再作成のたびに確認をやり直すことになる。
#   OIDCプロバイダをcommonに置いているのと同じ考え方。
###############################################################################

locals {
  ssm_prefix = "/${var.project}/${var.environment}/monitoring"
}

# 通知先メールアドレス。パブリックリポジトリのため値はコードに置かず
# SSMから取得する。実値の設定は bootstrap 適用後にCLIで行う
data "aws_ssm_parameter" "alert_email" {
  name = "${local.ssm_prefix}/alert_email"
}

resource "aws_sns_topic" "this" {
  name         = "${var.project}-${var.environment}-alerts"
  display_name = "${var.project}-${var.environment} alerts"

  tags = {
    Name = "${var.project}-${var.environment}-alerts"
  }
}

###############################################################################
# メール購読
#
# 重要: applyが成功しても、購読は PendingConfirmation 状態で作られる。
# AWSから届く確認メールのリンクをクリックするまで通知は一切届かない。
#
# Terraformはこの確認を代行できない。第三者のアドレスを勝手に登録できて
# しまうため、人の操作を必須とする仕様になっている。
#
# 確認状況の見方:
#   aws sns list-subscriptions-by-topic --topic-arn <arn> \
#     --query 'Subscriptions[].[Protocol,Endpoint,SubscriptionArn]' --output table
#
#   SubscriptionArn が "PendingConfirmation" のままなら未確認。
###############################################################################
resource "aws_sns_topic_subscription" "email" {
  topic_arn = aws_sns_topic.this.arn
  protocol  = "email"
  endpoint  = data.aws_ssm_parameter.alert_email.value
}
