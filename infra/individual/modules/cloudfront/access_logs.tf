###############################################################################
# CloudFrontアクセスログ
#
# WAFログには「WAFが評価したリクエスト」しか残らない。CloudFront自身の
# ログを出すことで、全リクエストが記録される。
#
# ALBアクセスログとは記録される内容が違う。
#   ALBログ          送信元はCloudFrontのIP。オリジンでの処理時間やWAF遮断
#   CloudFrontログ   閲覧者の実IP・エッジロケーション・キャッシュ状況
#
# 実IPを知りたい場合はこちらを見る。ALBログからは分からない。
###############################################################################

resource "aws_s3_bucket" "logs" {
  count = var.cloudfront.access_logs_enabled ? 1 : 0

  bucket = "${local.name}-cf-logs"

  # 検証環境のためログが残っていても削除できるようにする
  force_destroy = true

  tags = {
    Name = "${local.name}-cf-logs"
  }
}

# CloudFrontの標準ログ配信はバケットACLを使う。
# S3の既定は「バケット所有者強制」でACLが無効なため、明示的に有効化しないと
# ログ配信の設定時に InvalidArgument で失敗する
resource "aws_s3_bucket_ownership_controls" "logs" {
  count = var.cloudfront.access_logs_enabled ? 1 : 0

  bucket = aws_s3_bucket.logs[0].id

  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_public_access_block" "logs" {
  count = var.cloudfront.access_logs_enabled ? 1 : 0

  bucket = aws_s3_bucket.logs[0].id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "logs" {
  count = var.cloudfront.access_logs_enabled ? 1 : 0

  bucket = aws_s3_bucket.logs[0].id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "logs" {
  count = var.cloudfront.access_logs_enabled ? 1 : 0

  bucket = aws_s3_bucket.logs[0].id

  rule {
    id     = "expire"
    status = "Enabled"

    filter {}

    expiration {
      days = var.cloudfront.access_logs_retention_days
    }

    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }
}
