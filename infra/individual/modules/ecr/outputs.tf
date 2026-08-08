output "repository_name" {
  description = "ECRリポジトリ名"
  value       = aws_ecr_repository.this.name
}

output "repository_url" {
  description = "ECRリポジトリのURL（docker pushの宛先）"
  value       = aws_ecr_repository.this.repository_url
}

output "repository_arn" {
  description = "ECRリポジトリのARN（IAMポリシーのリソース指定に使う）"
  value       = aws_ecr_repository.this.arn
}
