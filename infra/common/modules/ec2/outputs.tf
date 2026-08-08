output "bastion_public_ip" {
  description = "Bastion host public IP"
  value       = aws_instance.bastion.public_ip
}

output "bastion_security_group_id" {
  description = "Bastion host security group ID"
  value       = aws_security_group.bastion.id
}

output "secrets_bucket_name" {
  description = "S3 bucket name for secrets"
  value       = aws_s3_bucket.secrets.bucket
}

output "bastion_ssh_key_s3_path" {
  description = "S3 path of the bastion SSH private key"
  value       = "s3://${aws_s3_bucket.secrets.bucket}/${aws_s3_object.bastion_private_key.key}"
}

output "bastion_ssh_command" {
  description = "Command to download the SSH key from S3 and connect to bastion"
  value       = "aws s3 cp s3://${aws_s3_bucket.secrets.bucket}/${aws_s3_object.bastion_private_key.key} . && chmod 600 ${aws_s3_object.bastion_private_key.key} && ssh -i ${aws_s3_object.bastion_private_key.key} ubuntu@${aws_instance.bastion.public_ip}"
}
