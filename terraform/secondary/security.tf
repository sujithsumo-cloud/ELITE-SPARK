# ============================================================
# MUMBAI ALB SECURITY GROUP
# ============================================================

resource "aws_security_group" "alb" {
  name        = "MUM-ALB-SG"
  description = "Allow public HTTP traffic to Mumbai DR ALB"
  vpc_id      = aws_vpc.dr.id

  ingress {
    description = "HTTP from Internet"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "MUM-ALB-SG"
  }
}


# ============================================================
# MUMBAI APPLICATION SECURITY GROUP
# Only ALB can reach application port 5000.
# ============================================================

resource "aws_security_group" "app" {
  name        = "MUM-APP-SG"
  description = "Allow application traffic from Mumbai ALB"
  vpc_id      = aws_vpc.dr.id

  ingress {
    description     = "Application traffic from ALB"
    from_port       = 5000
    to_port         = 5000
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "MUM-APP-SG"
  }
}


# ============================================================
# VPC ENDPOINT SECURITY GROUP
# ============================================================

resource "aws_security_group" "endpoints" {
  name        = "MUM-ENDPOINT-SG"
  description = "Allow HTTPS from Mumbai application instances"
  vpc_id      = aws_vpc.dr.id

  ingress {
    description     = "HTTPS from application instances"
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    security_groups = [aws_security_group.app.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "MUM-ENDPOINT-SG"
  }
}