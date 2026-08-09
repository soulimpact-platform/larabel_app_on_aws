###############################################################################
# ECR Repository
#
# アプリ(php-fpm)とnginxで別リポジトリを使うため for_each で複数作る。
###############################################################################
resource "aws_ecr_repository" "this" {
  for_each = var.ecr

  name = "${var.project}-${var.environment}-${each.key}"

  # MUTABLE: gitのSHAタグに加えてlatestタグも更新するため。
  # SHAタグのみ運用に切り替えるならIMMUTABLEの方が安全
  image_tag_mutability = each.value.image_tag_mutability

  force_delete = each.value.force_delete

  image_scanning_configuration {
    scan_on_push = true
  }

  encryption_configuration {
    encryption_type = "AES256"
  }

  tags = {
    Name = "${var.project}-${var.environment}-${each.key}"
  }
}

###############################################################################
# Lifecycle Policy
#
# 放置するとイメージが際限なく溜まりストレージ課金が増えるため、
# 古いものを自動削除する
###############################################################################
resource "aws_ecr_lifecycle_policy" "this" {
  for_each = var.ecr

  repository = aws_ecr_repository.this[each.key].name

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
        description  = "直近${each.value.keep_image_count}世代のみ保持"
        selection = {
          tagStatus   = "any"
          countType   = "imageCountMoreThan"
          countNumber = each.value.keep_image_count
        }
        action = {
          type = "expire"
        }
      }
    ]
  })
}
