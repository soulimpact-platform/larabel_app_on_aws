output "ecr_repository_url" {
  description = "ECRリポジトリのURL（docker pushの宛先）"
  value       = module.ecr.repository_url
}

output "ecr_repository_name" {
  description = "ECRリポジトリ名（ワークフローのECR_REPOSITORYに設定する値）"
  value       = module.ecr.repository_name
}

output "github_actions_role_arn" {
  description = "GitHub Actionsに設定するIAMロールARN（リポジトリ変数 AWS_DEPLOY_ROLE_ARN）"
  value       = module.sts_assume_role.role_arn
}
