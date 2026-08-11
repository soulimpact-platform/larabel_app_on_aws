output "arn" {
  description = "SNSトピックARN（アラームの alarm_actions に指定する）"
  value       = aws_sns_topic.this.arn
}

output "name" {
  description = "SNSトピック名"
  value       = aws_sns_topic.this.name
}

output "subscription_arn" {
  description = "メール購読のARN。PendingConfirmation のままなら未確認"
  value       = aws_sns_topic_subscription.email.arn
}
