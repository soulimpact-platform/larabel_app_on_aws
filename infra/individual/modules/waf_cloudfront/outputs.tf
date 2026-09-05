output "web_acl_arn" {
  description = "CloudFrontにアタッチするWeb ACLのARN"
  value       = aws_wafv2_web_acl.this.arn
}

output "web_acl_name" {
  description = "Web ACL名"
  value       = aws_wafv2_web_acl.this.name
}

output "log_group_name" {
  description = "WAFログのロググループ名（us-east-1）"
  value       = aws_cloudwatch_log_group.waf.name
}
