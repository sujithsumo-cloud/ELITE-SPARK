# ============================================================
# ALB SECURITY GROUP
# Public HTTP is retained only for redirecting clients to HTTPS.
# HTTPS is the application entry point.
# ============================================================

resource "aws_security_group" "alb" {
  name        = "HYD-ALB-SG"
  description = "Allow public HTTP redirect and HTTPS traffic to Hyderabad ALB"
  vpc_id      = aws_vpc.primary.id

  ingress {
    description = "Allow HTTP from Internet for HTTPS redirect"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Allow HTTPS from Internet"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "HYD-ALB-SG"
  }
}

# ============================================================
# APPLICATION SECURITY GROUP
# Only the Hyderabad ALB can reach the application on port 5000.
# ============================================================

resource "aws_security_group" "app" {
  name        = "HYD-APP-SG"
  description = "Allow application traffic only from Hyderabad ALB"
  vpc_id      = aws_vpc.primary.id

  ingress {
    description     = "Allow Flask application traffic from ALB"
    from_port       = 5000
    to_port         = 5000
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  egress {
    description = "Allow outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "HYD-APP-SG"
  }
}
