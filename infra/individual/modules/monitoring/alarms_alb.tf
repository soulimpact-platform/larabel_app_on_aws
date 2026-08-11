###############################################################################
# ALB由来のアラーム
#
# ECSのCPUやメモリではなくALBのメトリクスを見るのは、ALBがユーザーと
# アプリの境界にあり「実際に何が返っているか」が唯一ここで分かるため。
# CPUが高くてもユーザーが使えているなら障害ではなく、CPUが低くても
# 500を返していれば重大障害である。
###############################################################################

###############################################################################
# ① 正常なターゲットが1台もない = サービス停止
#
# UnHealthyHostCount ではなく HealthyHostCount を見る。
#
#   タスクは動くがヘルスチェック失敗 : UnHealthy=1, Healthy=0
#   タスクが停止・登録解除された     : UnHealthy=0, Healthy=0  ← 前者では鳴らない
#
# 「完全に落ちている」という最も重い障害を取りこぼさないための選択。
###############################################################################
resource "aws_cloudwatch_metric_alarm" "healthy_host" {
  alarm_name        = "${local.name}-alb-healthy-host"
  alarm_description = "ALBに正常なターゲットが存在しない。サイトが応答していない可能性が高い"

  namespace   = "AWS/ApplicationELB"
  metric_name = "HealthyHostCount"
  dimensions  = local.alb_dimensions

  # 一瞬でも0になったら異常とみなすため Minimum
  statistic = "Minimum"

  # 直近2分ぶんを見て、2個とも閾値未満ならALARM。
  # 1個で鳴らすと瞬間的なブレで誤報が出る
  period              = 60
  evaluation_periods  = 2
  datapoints_to_alarm = 2
  threshold           = 1
  comparison_operator = "LessThanThreshold"

  # ターゲットが1台も無いとメトリクス自体が届かなくなる。
  # 既定の missing のままだとOKで固まり、停止を検知できない
  treat_missing_data = "breaching"

  alarm_actions = local.alarm_actions
  ok_actions    = local.ok_actions

  tags = {
    Name = "${local.name}-alb-healthy-host"
  }
}

###############################################################################
# ② アプリケーションが5XXを返している
#
# HTTPCode_ELB_5XX_Count（ALB自身が返す503など）とは別物。
# こちらはアプリまで到達した上でエラーになったリクエスト数を指す。
###############################################################################
resource "aws_cloudwatch_metric_alarm" "target_5xx" {
  alarm_name        = "${local.name}-alb-target-5xx"
  alarm_description = "アプリケーションが5XXを返している"

  namespace   = "AWS/ApplicationELB"
  metric_name = "HTTPCode_Target_5XX_Count"
  dimensions  = local.alb_dimensions

  # 件数なので合計する
  statistic = "Sum"

  period              = 300
  evaluation_periods  = 1
  threshold           = var.monitoring.alb.target_5xx_threshold
  comparison_operator = "GreaterThanOrEqualToThreshold"

  # データが無い = エラーが1件も発生していない = 正常
  treat_missing_data = "notBreaching"

  alarm_actions = local.alarm_actions
  ok_actions    = local.ok_actions

  tags = {
    Name = "${local.name}-alb-target-5xx"
  }
}

###############################################################################
# ③ レスポンスが遅い（劣化の予兆）
#
# statistic ではなく extended_statistic で p95 を指定する。
# Average で見ると、1割のユーザーが10秒待たされていても
# 残り9割が0.1秒なら平均1.1秒となり、異常が埋もれる。
###############################################################################
resource "aws_cloudwatch_metric_alarm" "response_time" {
  alarm_name        = "${local.name}-alb-response-time"
  alarm_description = "レスポンスタイム(p95)が閾値を超過。障害の予兆"

  namespace   = "AWS/ApplicationELB"
  metric_name = "TargetResponseTime"
  dimensions  = local.alb_dimensions

  # statistic とは排他。p95のような分位数はこちらで指定する
  extended_statistic = "p95"

  period              = 300
  evaluation_periods  = 2
  datapoints_to_alarm = 2
  threshold           = var.monitoring.alb.response_time_threshold
  comparison_operator = "GreaterThanThreshold"

  # リクエストが無ければデータも無い。無通信は異常ではない
  treat_missing_data = "notBreaching"

  alarm_actions = local.alarm_actions
  ok_actions    = local.ok_actions

  tags = {
    Name = "${local.name}-alb-response-time"
  }
}
