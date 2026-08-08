###############################################################################
# GitHub Actions が引き受けるIAMロール
#
# 信頼の起点であるOIDCプロバイダ（common側で作成）を参照し、
# 「どのリポジトリのどのブランチなら引き受けてよいか」をここで決める。
#
# プロバイダはアカウントに1つだが、このロールは用途ごとに複数作れる。
# そのため個別対応用の individual 側に置いている。
###############################################################################

###############################################################################
# 信頼ポリシー
#
# audとsubの両方を検証する。subを絞らないと「GitHub上の任意のリポジトリ」から
# このロールを引き受けられてしまうため、リポジトリとref（ブランチ）まで限定する。
###############################################################################
data "aws_iam_policy_document" "assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [var.oidc_provider_arn]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values   = var.github.allowed_subjects
    }
  }
}

resource "aws_iam_role" "this" {
  name               = "${var.project}-${var.environment}-${var.github.role_name}"
  description        = "Role assumed by GitHub Actions via OIDC"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json

  tags = {
    Name = "${var.project}-${var.environment}-${var.github.role_name}"
  }
}

###############################################################################
# 権限: ECRへのイメージプッシュ
###############################################################################
data "aws_iam_policy_document" "ecr_push" {
  # ログイントークンの取得。このアクションはリソースを限定できない
  statement {
    sid       = "GetAuthorizationToken"
    effect    = "Allow"
    actions   = ["ecr:GetAuthorizationToken"]
    resources = ["*"]
  }

  # 実際の読み書きは対象リポジトリのみに限定する
  statement {
    sid    = "PushAndPullImages"
    effect = "Allow"
    actions = [
      "ecr:BatchCheckLayerAvailability",
      "ecr:InitiateLayerUpload",
      "ecr:UploadLayerPart",
      "ecr:CompleteLayerUpload",
      "ecr:PutImage",
      "ecr:BatchGetImage",
      "ecr:GetDownloadUrlForLayer",
      "ecr:DescribeImages",
      "ecr:DescribeRepositories",
    ]
    resources = var.ecr_repository_arns
  }
}

resource "aws_iam_role_policy" "ecr_push" {
  name   = "${var.project}-${var.environment}-ecr-push"
  role   = aws_iam_role.this.id
  policy = data.aws_iam_policy_document.ecr_push.json
}
