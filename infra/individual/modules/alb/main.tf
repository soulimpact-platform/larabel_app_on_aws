###############################################################################
# Route53 ホストゾーン（既存のものを参照する）
#
# ゾーン自体はこのプロジェクトの管理外（他プロジェクトのレコードも同居）。
# 作成せず参照のみ行い、このアプリ用のレコードだけを追加する。
###############################################################################
data "aws_route53_zone" "this" {
  name         = var.dns.zone_name
  private_zone = false
}

locals {
  fqdn = "${var.dns.record_name}.${var.dns.zone_name}"
}

###############################################################################
# ACM証明書（DNS検証）
#
# ALBに付ける証明書はALBと同じリージョンに必要（CloudFrontはus-east-1）。
# 検証用レコードを同じホストゾーンに作れるため、発行は全自動で完了する。
###############################################################################
resource "aws_acm_certificate" "this" {
  domain_name       = local.fqdn
  validation_method = "DNS"

  tags = {
    Name = local.fqdn
  }

  # 証明書を差し替える際、先に新しいものを作ってから古いものを外す
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route53_record" "certificate_validation" {
  for_each = {
    for dvo in aws_acm_certificate.this.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      type   = dvo.resource_record_type
      record = dvo.resource_record_value
    }
  }

  zone_id         = data.aws_route53_zone.this.zone_id
  name            = each.value.name
  type            = each.value.type
  records         = [each.value.record]
  ttl             = 60
  allow_overwrite = true
}

# 検証完了までapplyをブロックする。
# これが無いと未検証の証明書をリスナーに付けようとして失敗する
resource "aws_acm_certificate_validation" "this" {
  certificate_arn         = aws_acm_certificate.this.arn
  validation_record_fqdns = [for r in aws_route53_record.certificate_validation : r.fqdn]
}

###############################################################################
# ALB Security Group
#
# インターネットからのHTTP/HTTPSを受ける。
# ECSタスク側は「このSGからのみ」を許可することで、ALB経由の
# アクセスだけに限定する（タスクに直接到達できない）。
###############################################################################
resource "aws_security_group" "alb" {
  name        = "${var.project}-${var.environment}-alb-sg"
  description = "Security group for the application load balancer"
  vpc_id      = var.vpc_id

  ingress {
    description = "HTTPS from internet"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = var.alb.allowed_cidrs
  }

  # HTTPSへリダイレクトするためだけに開けている
  ingress {
    description = "HTTP from internet (redirected to HTTPS)"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = var.alb.allowed_cidrs
  }

  egress {
    description = "To ECS tasks"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project}-${var.environment}-alb-sg"
  }
}

###############################################################################
# Application Load Balancer
#
# ALBはマルチAZ必須のため、Publicサブネットを2つ以上渡す必要がある。
###############################################################################
resource "aws_lb" "this" {
  name               = "${var.project}-${var.environment}-alb"
  load_balancer_type = "application"
  internal           = false
  subnets            = var.subnet_ids
  security_groups    = [aws_security_group.alb.id]

  idle_timeout               = var.alb.idle_timeout
  enable_deletion_protection = var.alb.enable_deletion_protection

  tags = {
    Name = "${var.project}-${var.environment}-alb"
  }
}

###############################################################################
# Target Group
#
# ECSサービスがタスクのIPをここへ登録する（awsvpcのためtarget_type = ip）。
# ヘルスチェックはLaravelが標準で用意する /up を使う。
###############################################################################
resource "aws_lb_target_group" "this" {
  name        = "${var.project}-${var.environment}-tg"
  port        = var.alb.target_port
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"

  # タスク停止時に接続を待つ時間。デプロイの切り替えが速くなるよう短めにする
  deregistration_delay = var.alb.deregistration_delay

  health_check {
    enabled             = true
    path                = var.alb.health_check_path
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 3
  }

  tags = {
    Name = "${var.project}-${var.environment}-tg"
  }

  # ALBに紐づいたまま作り直すとエラーになるため
  lifecycle {
    create_before_destroy = true
  }
}

###############################################################################
# Listener
#
# 443: 証明書を付けてECSへ転送
# 80 : 443へ恒久リダイレクト（平文で受け付けない）
###############################################################################
resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.this.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = var.alb.ssl_policy

  # 検証完了後のARNを参照することで、発行待ちの証明書を付けないようにする
  certificate_arn = aws_acm_certificate_validation.this.certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.this.arn
  }
}

resource "aws_lb_listener" "http_redirect" {
  load_balancer_arn = aws_lb.this.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

###############################################################################
# Aレコード（ALBへのAlias）
#
# ALBのIPは変動するため、IPを直接書くAレコードではなくAliasを使う。
# Aliasはゾーン内部で解決されるためクエリ課金も発生しない。
###############################################################################
resource "aws_route53_record" "this" {
  zone_id = data.aws_route53_zone.this.zone_id
  name    = local.fqdn
  type    = "A"

  alias {
    name                   = aws_lb.this.dns_name
    zone_id                = aws_lb.this.zone_id
    evaluate_target_health = true
  }
}
