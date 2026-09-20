# ============================================================
# HYDERABAD APPLICATION TARGET GROUP
# ============================================================

resource "aws_lb_target_group" "app" {
  name        = "HYD-APP-TG"
  port        = 5000
  protocol    = "HTTP"
  vpc_id      = aws_vpc.primary.id
  target_type = "instance"

  health_check {
    enabled             = true
    path                = "/health"
    protocol            = "HTTP"
    port                = "traffic-port"
    matcher             = "200"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }

  tags = {
    Name = "HYD-APP-TG"
  }
}


# ============================================================
# HYDERABAD APPLICATION LOAD BALANCER
# Public ALB across both public Availability Zones.
# ============================================================

resource "aws_lb" "app" {
  name               = "HYD-ALB"
  internal           = false
  load_balancer_type = "application"

  security_groups = [
    aws_security_group.alb.id
  ]

  subnets = [
    aws_subnet.public_a.id,
    aws_subnet.public_b.id
  ]

  enable_deletion_protection = false

  tags = {
    Name = "HYD-ALB"
  }
}


# ============================================================
# EXISTING ACM CERTIFICATE
# Certificate was issued manually in ACM for the application
# hostname. Terraform reads the issued certificate and attaches
# it to the Hyderabad HTTPS listener; Terraform does not own or
# delete the certificate.
# ============================================================

data "aws_acm_certificate" "finance" {
  domain      = "finance.best.2bd.net"
  statuses    = ["ISSUED"]
  most_recent = true
}


# ============================================================
# HTTP LISTENER
# Keep port 80 available only to redirect clients to HTTPS.
# ============================================================

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.app.arn
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


# ============================================================
# HTTPS LISTENER
# TLS terminates at the ALB. The ALB then forwards HTTP traffic
# privately to the Docker application on target-group port 5000.
# ============================================================

resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.app.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"
  certificate_arn   = data.aws_acm_certificate.finance.arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app.arn
  }
}
