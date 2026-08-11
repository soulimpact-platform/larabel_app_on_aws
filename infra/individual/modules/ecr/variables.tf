variable "project" {
  description = "Project name"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

# 既定値はここが唯一の置き場。呼び出し側は変えたい項目だけを書く。
# 属性を省略した場合も null を明示した場合も、ここの既定値が適用される。
variable "ecr" {
  description = "ECR repositories（キーがリポジトリ名の接尾辞になる）"
  type = map(object({
    # latestタグを更新するためMUTABLE
    image_tag_mutability = optional(string, "MUTABLE")
    keep_image_count     = optional(number, 10)
    # 既定は安全側。イメージが残っていたらリポジトリを消させない
    force_delete = optional(bool, false)
  }))
}
