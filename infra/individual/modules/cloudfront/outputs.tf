output "fqdn" {
  description = "パートナー向けの公開ドメイン名"
  value       = local.fqdn
}

output "url" {
  description = "パートナー向けのURL"
  value       = "https://${local.fqdn}"
}

output "distribution_id" {
  description = "CloudFrontディストリビューションID（キャッシュ削除などに使う）"
  value       = aws_cloudfront_distribution.this.id
}

output "distribution_domain_name" {
  description = "CloudFrontのドメイン名（Route53 Aliasの向き先。通常は直接使わない）"
  value       = aws_cloudfront_distribution.this.domain_name
}

output "certificate_arn" {
  description = "発行したACM証明書のARN（us-east-1）"
  value       = aws_acm_certificate_validation.this.certificate_arn
}
