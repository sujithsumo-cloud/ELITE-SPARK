# ============================================================
# MUMBAI DISASTER RECOVERY NETWORK
# ============================================================

data "aws_availability_zones" "available" {
  state = "available"
}


# ============================================================
# DR VPC
# ============================================================

resource "aws_vpc" "dr" {
  cidr_block           = "10.1.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "DR-VPC"
  }
}


# ============================================================
# INTERNET GATEWAY
# ============================================================

resource "aws_internet_gateway" "mum" {
  vpc_id = aws_vpc.dr.id

  tags = {
    Name = "MUM-IGW"
  }
}


# ============================================================
# PUBLIC SUBNET A
# ============================================================

resource "aws_subnet" "public_a" {
  vpc_id                  = aws_vpc.dr.id
  cidr_block              = "10.1.0.0/27"
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = false

  tags = {
    Name = "PUB-MUM-SUB-A"
  }
}


# ============================================================
# PUBLIC SUBNET B
# ============================================================

resource "aws_subnet" "public_b" {
  vpc_id                  = aws_vpc.dr.id
  cidr_block              = "10.1.0.32/27"
  availability_zone       = data.aws_availability_zones.available.names[1]
  map_public_ip_on_launch = false

  tags = {
    Name = "PUB-MUM-SUB-B"
  }
}


# ============================================================
# PRIVATE SUBNET A
# ============================================================

resource "aws_subnet" "private_a" {
  vpc_id            = aws_vpc.dr.id
  cidr_block        = "10.1.1.0/27"
  availability_zone = data.aws_availability_zones.available.names[0]

  tags = {
    Name = "PRI-MUM-SUB-A"
  }
}


# ============================================================
# PRIVATE SUBNET B
# ============================================================

resource "aws_subnet" "private_b" {
  vpc_id            = aws_vpc.dr.id
  cidr_block        = "10.1.1.32/27"
  availability_zone = data.aws_availability_zones.available.names[1]

  tags = {
    Name = "PRI-MUM-SUB-B"
  }
}


# ============================================================
# PUBLIC ROUTE TABLE
# ============================================================

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.dr.id

  tags = {
    Name = "MUM-PUB-RT"
  }
}


resource "aws_route" "public_internet" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.mum.id
}


# ============================================================
# PRIVATE ROUTE TABLE
#
# No Internet default route.
# NAT Gateway intentionally not used.
# ============================================================

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.dr.id

  tags = {
    Name = "MUM-PRI-RT"
  }
}


# ============================================================
# ROUTE TABLE ASSOCIATIONS
# ============================================================

resource "aws_route_table_association" "public_a" {
  subnet_id      = aws_subnet.public_a.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public_b" {
  subnet_id      = aws_subnet.public_b.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "private_a" {
  subnet_id      = aws_subnet.private_a.id
  route_table_id = aws_route_table.private.id
}

resource "aws_route_table_association" "private_b" {
  subnet_id      = aws_subnet.private_b.id
  route_table_id = aws_route_table.private.id
}