###############################################################################
# 監視（アラーム定義）
#
# 通知先のSNSトピックはcommon側で作成済みのものを受け取る。
# このモジュールは「閾値を引く」ことだけを担当する。
#
# メトリクス自体はここでは作らない。ALBがCloudWatchへ自動で送出しており、
# Terraformで作成できる類のリソースではないため（値が書き込まれた瞬間に
# 存在し始めるデータであり、設定項目も作成APIも持たない）。
#
# ファイル構成:
#   main.tf        共通のlocals
#   alarms_alb.tf  ALB由来のアラーム
#   （将来）alarms_rds.tf / log_metrics.tf
###############################################################################

locals {
  name = "${var.project}-${var.environment}"

  # 状態遷移の両方向を通知する。
  # ok_actions を省くと「鳴りっぱなしなのか直ったのか分からない」状態になり、
  # アラート自体が信用されなくなる
  alarm_actions = [var.alert_topic_arn]
  ok_actions    = [var.alert_topic_arn]

  # ALB系アラーム共通のディメンション。
  # TargetGroup を省くとALB全体の集計になり、TGが増えたときに誤検知する
  alb_dimensions = {
    LoadBalancer = var.alb.arn_suffix
    TargetGroup  = var.alb.target_group_arn_suffix
  }
}
