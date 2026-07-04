# infra

AWS上に本番環境を構築するためのTerraformコードを配置するディレクトリです。

## 想定構成

- CloudFront → ALB → ECS(Fargate)
- ECSタスク内: nginx + php-fpm（`app/`と同じコンテナ構成）
- RDS for MySQL

## 現状

Terraformコードは未着手です。今後このディレクトリ配下に追加していきます。
