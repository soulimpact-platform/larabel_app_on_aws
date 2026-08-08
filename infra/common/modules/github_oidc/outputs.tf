output "oidc_provider_arn" {
  description = "GitHub ActionsのOIDCプロバイダARN"
  value       = aws_iam_openid_connect_provider.github.arn
}

output "oidc_provider_url" {
  description = "OIDCプロバイダのURL（individual側のdata sourceで参照する値）"
  value       = aws_iam_openid_connect_provider.github.url
}
