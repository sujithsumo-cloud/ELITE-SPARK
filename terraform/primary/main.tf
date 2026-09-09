# ============================================================
# AVAILABLE AVAILABILITY ZONES
# ============================================================

data "aws_availability_zones" "available" {
  state = "available"
}


# ============================================================
# PRIMARY VPC - HYDERABAD
# ============================================================

resource "aws_vpc" "primary" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "PRI-VPC"
  }
}


# ============================================================
# INTERNET GATEWAY
# ============================================================

resource "aws_internet_gateway" "hyd" {
  vpc_id = aws_vpc.primary.id

  tags = {
    Name = "HYD-IGW"
  }
}


# ============================================================
# PUBLIC SUBNET - AZ A
# ============================================================

resource "aws_subnet" "public_a" {
  vpc_id                  = aws_vpc.primary.id
  cidr_block              = "10.0.0.0/27"
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = false

  tags = {
    Name = "PUB-HYD-SUB-A"
    Tier = "Public"
  }
}


# ============================================================
# PUBLIC SUBNET - AZ B
# ============================================================

resource "aws_subnet" "public_b" {
  vpc_id                  = aws_vpc.primary.id
  cidr_block              = "10.0.0.32/27"
  availability_zone       = data.aws_availability_zones.available.names[1]
  map_public_ip_on_launch = false

  tags = {
    Name = "PUB-HYD-SUB-B"
    Tier = "Public"
  }
}


# ============================================================
# PRIVATE SUBNET - AZ A
# ============================================================

resource "aws_subnet" "private_a" {
  vpc_id            = aws_vpc.primary.id
  cidr_block        = "10.0.1.0/27"
  availability_zone = data.aws_availability_zones.available.names[0]

  tags = {
    Name = "PRI-HYD-SUB-A"
    Tier = "Private"
  }
}


# ============================================================
# PRIVATE SUBNET - AZ B
# ============================================================

resource "aws_subnet" "private_b" {
  vpc_id            = aws_vpc.primary.id
  cidr_block        = "10.0.1.32/27"
  availability_zone = data.aws_availability_zones.available.names[1]

  tags = {
    Name = "PRI-HYD-SUB-B"
    Tier = "Private"
  }
}


# ============================================================
# PUBLIC ROUTE TABLE
# ============================================================

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.primary.id

  tags = {
    Name = "HYD-PUB-RT"
  }
}


# ============================================================
# PUBLIC INTERNET ROUTE
# ============================================================

resource "aws_route" "public_internet" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.hyd.id
}


# ============================================================
# PRIVATE ROUTE TABLE
# ============================================================

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.primary.id

  tags = {
    Name = "HYD-PRI-RT"
  }
}


# ============================================================
# PUBLIC ROUTE TABLE ASSOCIATIONS
# ============================================================

resource "aws_route_table_association" "public_a" {
  subnet_id      = aws_subnet.public_a.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public_b" {
  subnet_id      = aws_subnet.public_b.id
  route_table_id = aws_route_table.public.id
}


# ============================================================
# PRIVATE ROUTE TABLE ASSOCIATIONS
# ============================================================

resource "aws_route_table_association" "private_a" {
  subnet_id      = aws_subnet.private_a.id
  route_table_id = aws_route_table.private.id
}

resource "aws_route_table_association" "private_b" {
  subnet_id      = aws_subnet.private_b.id
  route_table_id = aws_route_table.private.id
}