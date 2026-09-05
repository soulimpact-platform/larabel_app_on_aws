###############################################################################
# ALBアクセスログ
#
# WAFログには「WAFが評価したリクエスト」しか残らず、リスナールールが返す
# 403（CloudFrontを経由しない /partner/* への直叩きなど）は記録されない。
# 経路の実態を追えるようにするため、ALB自身のアクセスログを出す。
#
# 出力先はS3のみ（ALBはCloudWatch Logsへ直接出力できない）。
# 暗号化はSSE-S3(AES256)のみ対応で、SSE-KMSのCMKは使えない。
###############################################################################

data "aws_elb_service_account" "current" {
  count = var.alb.access_logs_enabled ? 1 : 0
}

resource "aws_s3_bucket" "access_logs" {
  count = var.alb.access_logs_enabled ? 1 : 0

  bucket = "${var.project}-${var.environment}-alb-logs"

  # 検証環境のためログが残っていても削除できるようにする。
  # 本運用では false にしてログの誤消去を防ぐこと
  force_destroy = true

  tags = {
    Name = "${var.project}-${var.environment}-alb-logs"
  }
}

resource "aws_s3_bucket_public_access_block" "access_logs" {
  count = var.alb.access_logs_enabled ? 1 : 0

  bucket = aws_s3_bucket.access_logs[0].id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "access_logs" {
  count = var.alb.access_logs_enabled ? 1 : 0

  bucket = aws_s3_bucket.access_logs[0].id

  rule {
    apply_server_side_encryption_by_default {
      # ALBアクセスログはSSE-S3のみ対応。KMSのCMKを指定すると配信に失敗する
      sse_algorithm = "AES256"
    }
  }
}

# ログは放置すると増え続けるため、保持期間を過ぎたものを自動削除する
resource "aws_s3_bucket_lifecycle_configuration" "access_logs" {
  count = var.alb.access_logs_enabled ? 1 : 0

  bucket = aws_s3_bucket.access_logs[0].id

  rule {
    id     = "expire"
    status = "Enabled"

    filter {}

    expiration {
      days = var.alb.access_logs_retention_days
    }

    # 途中で失敗したマルチパートアップロードの残骸も掃除する
    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }
}

# ALBがログを書き込めるようにする。
# ap-northeast-1 は旧世代リージョンのため、サービスプリンシパルではなく
# ELB用のAWSアカウントIDを principal に指定する方式を使う
resource "aws_s3_bucket_policy" "access_logs" {
  count = var.alb.access_logs_enabled ? 1 : 0

  bucket = aws_s3_bucket.access_logs[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowELBLogDelivery"
        Effect = "Allow"
        Principal = {
          AWS = data.aws_elb_service_account.current[0].arn
        }
        Action   = "s3:PutObject"
        Resource = "${aws_s3_bucket.access_logs[0].arn}/${var.alb.access_logs_prefix}/AWSLogs/${data.aws_caller_identity.current.account_id}/*"
      }
    ]
  })
}

data "aws_caller_identity" "current" {}
