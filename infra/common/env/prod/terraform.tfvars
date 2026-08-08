project     = "larabel-app"
environment = "prod"
region      = "ap-northeast-1"

# VPCモジュールの設定
vpc = {
  cidr                 = "10.0.0.0/16"
  public_subnet_cidrs  = ["10.0.1.0/24", "10.0.2.0/24"]
  private_subnet_cidrs = ["10.0.11.0/24", "10.0.12.0/24"]
  availability_zones   = ["ap-northeast-1a", "ap-northeast-1c"]
}

# EC2モジュールの設定（踏み台サーバー）
ec2 = {
  public_bastion = {
    instance_type     = "t3.micro"
    ssh_key_name      = "bastion-key"
    allowed_ssh_cidrs = ["0.0.0.0/0"]
  }
}

# RDSモジュールの設定（MySQL。db_name/username/passwordはSSMから取得）
rds = {
  engine_version         = "8.0" # ローカルのdocker-compose（mysql:8.0）に合わせる
  parameter_group_family = "mysql8.0"
  instance_class         = "db.t3.micro"
  allocated_storage      = 20  # gp3の最小値
  max_allocated_storage  = 100 # ここまでストレージ自動スケーリング
  port                   = 3306

  multi_az = false # コスト優先。可用性が必要になったらtrueへ

  backup_retention_period         = 7
  backup_window                   = "18:00-18:30"         # UTC。JST 03:00-03:30
  maintenance_window              = "sun:19:00-sun:20:00" # UTC。JST 日曜 04:00-05:00
  enabled_cloudwatch_logs_exports = ["error", "slowquery"]

  # 検証中のため削除しやすい設定にしている。本運用時は
  # deletion_protection = true / skip_final_snapshot = false に変更すること
  deletion_protection = false
  skip_final_snapshot = true

  # SSMのパスワードを更新したらこの数値を増やして再applyする
  password_version = 1
}
