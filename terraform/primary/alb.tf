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
# HTTP LISTENER
# Receives traffic on port 80 and forwards it to the
# application target group on port 5000.
# ============================================================

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.app.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app.arn
  }
}