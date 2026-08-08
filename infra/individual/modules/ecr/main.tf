###############################################################################
# ECR Repository
###############################################################################
resource "aws_ecr_repository" "this" {
  name = "${var.project}-${var.environment}-${var.ecr.repository_name}"

  # MUTABLE: gitのSHAタグに加えてlatestタグも更新するため。
  # SHAタグのみ運用に切り替えるならIMMUTABLEの方が安全
  image_tag_mutability = var.ecr.image_tag_mutability

  force_delete = var.ecr.force_delete

  image_scanning_configuration {
    scan_on_push = true
  }

  encryption_configuration {
    encryption_type = "AES256"
  }

  tags = {
    Name = "${var.project}-${var.environment}-${var.ecr.repository_name}"
  }
}

###############################################################################
# Lifecycle Policy
#
# 放置するとイメージが際限なく溜まりストレージ課金が増えるため、
# 古いものを自動削除する
###############################################################################
resource "aws_ecr_lifecycle_policy" "this" {
  repository = aws_ecr_repository.this.name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "タグなしイメージ（上書きで浮いた古いレイヤ）は1日で削除"
        selection = {
          tagStatus   = "untagged"
          countType   = "sinceImagePushed"
          countUnit   = "days"
          countNumber = 1
        }
        action = {
          type = "expire"
        }
      },
      {
        rulePriority = 2
        description  = "直近${var.ecr.keep_image_count}世代のみ保持"
        selection = {
          tagStatus   = "any"
          countType   = "imageCountMoreThan"
          countNumber = var.ecr.keep_image_count
        }
        action = {
          type = "expire"
        }
      }
    ]
  })
}
