output "web_acl_arn" {
  description = "Web ACLのARN"
  value       = aws_wafv2_web_acl.this.arn
}

output "web_acl_id" {
  description = "Web ACLのID"
  value       = aws_wafv2_web_acl.this.id
}

output "web_acl_name" {
  description = "Web ACL名（CloudWatchの WebACL ディメンション）"
  value       = aws_wafv2_web_acl.this.name
}

output "log_group_name" {
  description = "WAFログのロググループ名（Logs Insightsの検索対象）"
  value       = aws_cloudwatch_log_group.waf.name
}

output "count_only" {
  description = "COUNTモードで動作中かどうか（trueの間は一切ブロックしない）"
  value       = var.waf.count_only
}
