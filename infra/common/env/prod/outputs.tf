###############################################################################
# RDS
###############################################################################
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
