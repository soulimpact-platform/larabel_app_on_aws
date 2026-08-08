output "role_arn" {
  description = "GitHub Actionsが引き受けるIAMロールのARN（ワークフローのrole-to-assumeに設定する）"
  value       = aws_iam_role.this.arn
}

output "role_name" {
  description = "GitHub Actionsが引き受けるIAMロール名"
  value       = aws_iam_role.this.name
}
