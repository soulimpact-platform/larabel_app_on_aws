output "alarm_names" {
  description = "作成したアラーム名。set-alarm-state での疎通テストに使う"
  value = [
    aws_cloudwatch_metric_alarm.healthy_host.alarm_name,
    aws_cloudwatch_metric_alarm.target_5xx.alarm_name,
    aws_cloudwatch_metric_alarm.response_time.alarm_name,
  ]
}
