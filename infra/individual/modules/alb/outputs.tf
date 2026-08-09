output "fqdn" {
  description = "公開ドメイン名"
  value       = local.fqdn
}

output "url" {
  description = "アプリケーションのURL"
  value       = "https://${local.fqdn}"
}

output "dns_name" {
  description = "ALBのDNS名（Aliasの向き先。通常は直接使わない）"
  value       = aws_lb.this.dns_name
}

output "arn" {
  description = "ALBのARN"
  value       = aws_lb.this.arn
}

output "target_group_arn" {
  description = "ターゲットグループARN（ECSサービスが登録先として使う）"
  value       = aws_lb_target_group.this.arn
}

output "security_group_id" {
  description = "ALBのSG。ECSタスク側でこのSGからの通信のみを許可する"
  value       = aws_security_group.alb.id
}

output "certificate_arn" {
  description = "発行したACM証明書のARN"
  value       = aws_acm_certificate_validation.this.certificate_arn
}
