output "repository_names" {
  description = "ECRリポジトリ名（キーごと）"
  value       = { for k, v in aws_ecr_repository.this : k => v.name }
}

output "repository_urls" {
  description = "ECRリポジトリのURL（docker pushの宛先）"
  value       = { for k, v in aws_ecr_repository.this : k => v.repository_url }
}

output "repository_arns" {
  description = "ECRリポジトリのARN一覧（IAMポリシーのリソース指定に使う）"
  value       = [for v in aws_ecr_repository.this : v.arn]
}
