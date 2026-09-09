# ============================================================
# ECR API INTERFACE ENDPOINT
# ============================================================

resource "aws_vpc_endpoint" "ecr_api" {
  vpc_id              = aws_vpc.dr.id
  service_name        = "com.amazonaws.ap-south-1.ecr.api"
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
    Name = "MUM-ECR-API-ENDPOINT"
  }
}


# ============================================================
# ECR DOCKER INTERFACE ENDPOINT
# ============================================================

resource "aws_vpc_endpoint" "ecr_dkr" {
  vpc_id              = aws_vpc.dr.id
  service_name        = "com.amazonaws.ap-south-1.ecr.dkr"
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
    Name = "MUM-ECR-DKR-ENDPOINT"
  }
}


# ============================================================
# S3 GATEWAY ENDPOINT
# Required for ECR image layers and later S3 access.
# ============================================================

resource "aws_vpc_endpoint" "s3" {
  vpc_id            = aws_vpc.dr.id
  service_name      = "com.amazonaws.ap-south-1.s3"
  vpc_endpoint_type = "Gateway"

  route_table_ids = [
    aws_route_table.private.id
  ]

  tags = {
    Name = "MUM-S3-ENDPOINT"
  }
}


# ============================================================
# DYNAMODB GATEWAY ENDPOINT
# Future Mumbai application -> Global Table replica.
# ============================================================

resource "aws_vpc_endpoint" "dynamodb" {
  vpc_id            = aws_vpc.dr.id
  service_name      = "com.amazonaws.ap-south-1.dynamodb"
  vpc_endpoint_type = "Gateway"

  route_table_ids = [
    aws_route_table.private.id
  ]

  tags = {
    Name = "MUM-DYNAMODB-ENDPOINT"
  }
}