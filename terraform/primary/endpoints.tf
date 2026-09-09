# ============================================================
# VPC ENDPOINT SECURITY GROUP
# Allows private application EC2 instances to communicate
# with AWS interface endpoints over HTTPS.
# ============================================================

resource "aws_security_group" "endpoints" {
  name        = "HYD-ENDPOINT-SG"
  description = "Allow HTTPS from Hyderabad application instances to VPC endpoints"
  vpc_id      = aws_vpc.primary.id

  ingress {
    description     = "Allow HTTPS from application EC2 instances"
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    security_groups = [aws_security_group.app.id]
  }

  egress {
    description = "Allow outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "HYD-ENDPOINT-SG"
  }
}


# ============================================================
# ECR API INTERFACE ENDPOINT
# Used for ECR API operations such as authentication and
# repository/image metadata communication.
# ============================================================

resource "aws_vpc_endpoint" "ecr_api" {
  vpc_id              = aws_vpc.primary.id
  service_name        = "com.amazonaws.ap-south-2.ecr.api"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true

  subnet_ids = [
    aws_subnet.private_a.id,
    aws_subnet.private_b.id
  ]

  security_group_ids = [
    aws_security_group.endpoints.id
  ]

  tags = {
    Name = "HYD-ECR-API-ENDPOINT"
  }
}


# ============================================================
# ECR DOCKER INTERFACE ENDPOINT
# Used by Docker to pull the finance-app container image.
# ============================================================

resource "aws_vpc_endpoint" "ecr_dkr" {
  vpc_id              = aws_vpc.primary.id
  service_name        = "com.amazonaws.ap-south-2.ecr.dkr"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true

  subnet_ids = [
    aws_subnet.private_a.id,
    aws_subnet.private_b.id
  ]

  security_group_ids = [
    aws_security_group.endpoints.id
  ]

  tags = {
    Name = "HYD-ECR-DKR-ENDPOINT"
  }
}


# ============================================================
# S3 GATEWAY ENDPOINT
# ECR stores Docker image layers in Amazon S3.
# The private route table uses this endpoint without NAT.
# ============================================================

resource "aws_vpc_endpoint" "s3" {
  vpc_id            = aws_vpc.primary.id
  service_name      = "com.amazonaws.ap-south-2.s3"
  vpc_endpoint_type = "Gateway"

  route_table_ids = [
    aws_route_table.private.id
  ]

  tags = {
    Name = "HYD-S3-ENDPOINT"
  }
}
# ============================================================
# DYNAMODB GATEWAY ENDPOINT
#
# Allows private Hyderabad application instances to access
# DynamoDB without NAT Gateway or public Internet.
# ============================================================

resource "aws_vpc_endpoint" "dynamodb" {
  vpc_id            = aws_vpc.primary.id
  service_name      = "com.amazonaws.ap-south-2.dynamodb"
  vpc_endpoint_type = "Gateway"

  route_table_ids = [
    aws_route_table.private.id
  ]

  tags = {
    Name = "HYD-DYNAMODB-ENDPOINT"
  }
}