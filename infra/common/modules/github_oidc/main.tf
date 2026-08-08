###############################################################################
# GitHub Actions OIDC Provider
#
# GitHubが発行するIDトークンの署名を、AWSが検証できるようにするための土台。
# アクセスキーをGitHub Secretsに置く代わりに、実行のたびに一時認証情報を
# 発行させるための「信頼の起点」にあたる。
#
# このリソースはURLごとにAWSアカウント内で1つしか作れないため、
# common（アカウント共通の土台）側に置いている。
# 実際にロールを引き受ける側の定義は infra/individual/modules/sts_assume_role。
###############################################################################
resource "aws_iam_openid_connect_provider" "github" {
  url = "https://token.actions.githubusercontent.com"

  # audクレームの検証値。configure-aws-credentialsの既定値と一致させる
  client_id_list = ["sts.amazonaws.com"]

  # thumbprint_listは指定しない。GitHubのOIDCについてはAWSが自身の
  # 信頼ストアで検証するため、証明書更新のたびに更新する必要がない

  tags = {
    Name = "${var.project}-github-actions-oidc"
  }
}
