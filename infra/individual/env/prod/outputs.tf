###############################################################################
# アプリケーションの公開URL
###############################################################################
output "app_url" {
  description = "ブラウザからのアクセス先"
  value       = module.alb.url
}

output "alb_dns_name" {
  description = "ALBのDNS名（Aレコードの向き先）"
  value       = module.alb.dns_name
}

output "certificate_arn" {
  description = "発行したACM証明書のARN"
  value       = module.alb.certificate_arn
}

###############################################################################
# ECR / GitHub Actions
###############################################################################
output "ecr_repository_urls" {
  description = "ECRリポジトリのURL（docker pushの宛先）"
  value       = module.ecr.repository_urls
}

output "github_actions_role_arn" {
  description = "GitHub Actionsに設定するIAMロールARN（Environment変数 AWS_DEPLOY_ROLE_ARN）"
  value       = module.sts_assume_role.role_arn
}

###############################################################################
# ECS（ワークフローのenvに設定する値）
#
# クラスタ名・タスク定義・コンテナ名・ロググループ・ネットワーク構成は
# すべてこれらのパラメータの中にJSONで入っている
###############################################################################
output "ecs_migrate_runtime_parameter" {
  description = "migrate実行に必要な値を格納したSSMパラメータ名（ECS_MIGRATE_PARAM）"
  value       = module.ecs.migrate_runtime_parameter_name
}

output "ecs_web_runtime_parameter" {
  description = "Webデプロイに必要な値を格納したSSMパラメータ名（ECS_WEB_PARAM）"
  value       = module.ecs.web_runtime_parameter_name
}

output "ecs_cluster_name" {
  description = "ECSクラスタ名（確認用）"
  value       = module.ecs.cluster_name
}

output "ecs_web_service_name" {
  description = "ECSサービス名（確認用）"
  value       = module.ecs.web_service_name
}

output "ecs_log_group_name" {
  description = "実行ログが出るロググループ（確認用）"
  value       = module.ecs.log_group_name
}
