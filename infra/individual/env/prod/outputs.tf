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

###############################################################################
# ECS（ワークフローのenvに設定する値）
###############################################################################
# ワークフローの env に設定する唯一の値。
# クラスタ名・タスク定義・コンテナ名・ロググループ・ネットワーク構成は
# すべてこのパラメータの中にJSONで入っている
output "ecs_migrate_runtime_parameter" {
  description = "migrate実行に必要な値を格納したSSMパラメータ名（ワークフローの ECS_CONFIG_PARAM）"
  value       = module.ecs.migrate_runtime_parameter_name
}

output "ecs_cluster_name" {
  description = "ECSクラスタ名（確認用）"
  value       = module.ecs.cluster_name
}

output "ecs_log_group_name" {
  description = "migrateの実行ログが出るロググループ（確認用）"
  value       = module.ecs.log_group_name
}
