###############################################################################
# Secrets Bucket（bastion SSH秘密鍵の保管用）
# 将来、このバケットにのみ固有のIAMロール紐付け・バケットポリシー等を
# 追加する場合はここに追記する（tfstate用バケットの設定とは分離しておく）
###############################################################################
resource "aws_s3_bucket" "secrets" {
  bucket        = "${var.project}-${var.environment}-secrets"
  force_destroy = true

  tags = {
    Name = "${var.project}-${var.environment}-secrets"
  }
}

resource "aws_s3_bucket_versioning" "secrets" {
  bucket = aws_s3_bucket.secrets.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "secrets" {
  bucket = aws_s3_bucket.secrets.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "secrets" {
  bucket = aws_s3_bucket.secrets.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_object" "bastion_private_key" {
  bucket                 = aws_s3_bucket.secrets.id
  key                    = "${var.ec2.public_bastion.ssh_key_name}.pem"
  content                = tls_private_key.bastion.private_key_pem
  server_side_encryption = "AES256"
}
