output "cluster_name" {
  description = "ECSクラスタ名"
  value       = aws_ecs_cluster.this.name
}

output "cluster_arn" {
  description = "ECSクラスタARN"
  value       = aws_ecs_cluster.this.arn
}

output "migrate_runtime_parameter_name" {
  description = "migrate実行に必要な値を格納したSSMパラメータ名"
  value       = aws_ssm_parameter.migrate_runtime.name
}

output "web_runtime_parameter_name" {
  description = "Webデプロイに必要な値を格納したSSMパラメータ名"
  value       = aws_ssm_parameter.web_runtime.name
}

output "web_service_name" {
  description = "ECSサービス名"
  value       = aws_ecs_service.web.name
}

output "log_group_name" {
  description = "CloudWatch Logsのロググループ名"
  value       = aws_cloudwatch_log_group.this.name
}

output "log_group_arn" {
  description = "CloudWatch LogsのロググループARN"
  value       = aws_cloudwatch_log_group.this.arn
}

output "task_role_arns" {
  description = "run-task / update-service 時に iam:PassRole が必要となるロール"
  value       = [aws_iam_role.task_execution.arn, aws_iam_role.task.arn]
}

output "service_arns" {
  description = "CIが更新を許可されるECSサービスのARN"
  value       = [aws_ecs_service.web.id]
}

output "ssm_parameter_arn_prefix" {
  description = "CIが読むSSMパラメータのARN接頭辞"
  value       = "arn:${data.aws_partition.current.partition}:ssm:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:parameter/${var.project}/${var.environment}/ecs/*"
}
