variable "project" {
  description = "Project name"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "oidc_provider_arn" {
  description = "common側で作成したGitHub ActionsのOIDCプロバイダARN"
  type        = string
}

variable "github" {
  description = "GitHub Actions role configuration"
  type = object({
    role_name = string
    # ロールを引き受けられるワークフローの条件。
    # 例: "repo:<org>/<repo>:ref:refs/heads/main"
    #     "repo:<org>/<repo>:environment:prod"
    allowed_subjects = list(string)
  })
}

variable "ecr_repository_arns" {
  description = "プッシュを許可するECRリポジトリのARN"
  type        = list(string)
}

variable "ecs" {
  description = "migrateタスク実行を許可するための情報"
  type = object({
    cluster_arn              = string
    task_role_arns           = list(string)
    log_group_arn            = string
    ssm_parameter_arn_prefix = string
  })
}
