###############################################################################
# Network
#
# individual側の terraform_remote_state から参照される値。
# ここを消すとindividualのapplyが壊れるので注意。
###############################################################################
output "vpc_id" {
  description = "VPC ID"
  value       = module.vpc.vpc_id
}

output "public_subnet_ids" {
  description = "PublicサブネットのID（ALBの配置先。マルチAZ必須）"
  value       = module.vpc.public_subnet_ids
}

output "private_subnet_ids" {
  description = "PrivateサブネットのID（ECSタスクの配置先）"
  value       = module.vpc.private_subnet_ids
}

###############################################################################
# RDS
###############################################################################
output "rds_client_security_group_id" {
  description = "RDSへ接続するリソースに付与するSG（ECSタスクに着ける）"
  value       = module.rds.client_security_group_id
}

output "rds_address" {
  description = "RDSのホスト名（LaravelのDB_HOSTに設定する値）"
  value       = module.rds.address
}

output "rds_port" {
  description = "RDSのポート"
  value       = module.rds.port
}

output "rds_endpoint" {
  description = "RDSのエンドポイント（address:port）"
  value       = module.rds.endpoint
}

###############################################################################
# GitHub Actions OIDC
###############################################################################
output "github_oidc_provider_arn" {
  description = "OIDCプロバイダARN（individual側はURLでdata参照するため通常は不要）"
  value       = module.github_oidc.oidc_provider_arn
}

###############################################################################
# 監視
###############################################################################
output "alert_topic_arn" {
  description = "アラート通知先のSNSトピックARN（individual側のアラームが参照する）"
  value       = module.sns_alert_topic.arn
}

output "alert_subscription_arn" {
  description = "メール購読の状態。PendingConfirmation なら確認メール未クリック"
  value       = module.sns_alert_topic.subscription_arn
}

###############################################################################
# Bastion
###############################################################################
output "bastion_public_ip" {
  description = "踏み台サーバーのパブリックIP"
  value       = module.ec2.bastion_public_ip
}

output "bastion_ssh_command" {
  description = "踏み台へSSH接続するためのコマンド"
  value       = module.ec2.bastion_ssh_command
}
