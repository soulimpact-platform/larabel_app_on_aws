output "cluster_name" {
  description = "ECSクラスタ名"
  value       = aws_ecs_cluster.this.name
}

output "cluster_arn" {
  description = "ECSクラスタARN"
  value       = aws_ecs_cluster.this.arn
}

output "migrate_task_definition_family" {
  description = "migrate用タスク定義のファミリー名（CIはこれを基に新リビジョンを登録する）"
  value       = aws_ecs_task_definition.migrate.family
}

output "container_name" {
  description = "コンテナ名（CIがimageを差し替える対象）"
  value       = var.ecs.container_name
}

output "migrate_runtime_parameter_name" {
  description = "migrate実行に必要な値（クラスタ名・タスク定義・ネットワーク構成等）を格納したSSMパラメータ名"
  value       = aws_ssm_parameter.migrate_runtime.name
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
  description = "run-task時にiam:PassRoleが必要となるロール"
  value       = [aws_iam_role.task_execution.arn, aws_iam_role.task.arn]
}

output "ssm_parameter_arn_prefix" {
  description = "CIが読むSSMパラメータのARN接頭辞"
  value       = "arn:${data.aws_partition.current.partition}:ssm:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:parameter/${var.project}/${var.environment}/ecs/*"
}
