# ============================================================
# MUMBAI APPLICATION LOAD BALANCER
#
# Public ALB
#      ↓
# MUM-APP-TG :5000
#      ↓
# Private EC2 / Docker
# ============================================================


# ------------------------------------------------------------
# TARGET GROUP
# ------------------------------------------------------------

resource "aws_lb_target_group" "app" {

  name = "MUM-APP-TG"

  port     = 5000
  protocol = "HTTP"

  vpc_id = aws_vpc.dr.id

  target_type = "instance"

  health_check {
    enabled = true

    path     = "/health"
    protocol = "HTTP"
    port     = "traffic-port"

    matcher = "200"

    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }

  tags = {
    Name        = "MUM-APP-TG"
    Application = "finance-app"
  }
}


# ------------------------------------------------------------
# PUBLIC APPLICATION LOAD BALANCER
# ------------------------------------------------------------

resource "aws_lb" "app" {

  name = "MUM-ALB"

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
    Name        = "MUM-ALB"
    Application = "finance-app"
  }
}


# ------------------------------------------------------------
# HTTP LISTENER
# ------------------------------------------------------------

resource "aws_lb_listener" "http" {

  load_balancer_arn = aws_lb.app.arn

  port     = 80
  protocol = "HTTP"

  default_action {
    type = "forward"

    target_group_arn = aws_lb_target_group.app.arn
  }
}