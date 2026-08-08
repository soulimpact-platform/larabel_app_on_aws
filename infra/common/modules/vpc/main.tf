###############################################################################
# VPC
###############################################################################
resource "aws_vpc" "this" {
  cidr_block           = var.vpc.cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "${var.project}-${var.environment}-vpc"
  }
}

###############################################################################
# Public Subnets
###############################################################################
resource "aws_subnet" "public" {
  count                   = length(var.vpc.public_subnet_cidrs)
  vpc_id                  = aws_vpc.this.id
  cidr_block              = var.vpc.public_subnet_cidrs[count.index]
  availability_zone       = var.vpc.availability_zones[count.index]
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.project}-${var.environment}-public-${var.vpc.availability_zones[count.index]}"
  }
}

###############################################################################
# Private Subnets
###############################################################################
resource "aws_subnet" "private" {
  count             = length(var.vpc.private_subnet_cidrs)
  vpc_id            = aws_vpc.this.id
  cidr_block        = var.vpc.private_subnet_cidrs[count.index]
  availability_zone = var.vpc.availability_zones[count.index]

  tags = {
    Name = "${var.project}-${var.environment}-private-${var.vpc.availability_zones[count.index]}"
  }
}

###############################################################################
# Internet Gateway
###############################################################################
resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id

  tags = {
    Name = "${var.project}-${var.environment}-igw"
  }
}

###############################################################################
# Elastic IP for NAT Gateway
###############################################################################
resource "aws_eip" "nat" {
  domain = "vpc"

  tags = {
    Name = "${var.project}-${var.environment}-nat-eip"
  }
}

###############################################################################
# NAT Gateway (in first public subnet)
###############################################################################
resource "aws_nat_gateway" "this" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public[0].id

  tags = {
    Name = "${var.project}-${var.environment}-nat"
  }

  depends_on = [aws_internet_gateway.this]
}

###############################################################################
# Public Route Table
###############################################################################
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.this.id
  }

  tags = {
    Name = "${var.project}-${var.environment}-public-rt"
  }
}

resource "aws_route_table_association" "public" {
  count          = length(var.vpc.public_subnet_cidrs)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

###############################################################################
# Private Route Table（両AZともAZ-aのNAT Gateway経由）
###############################################################################
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.this.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.this.id
  }

  tags = {
    Name = "${var.project}-${var.environment}-private-rt"
  }
}

resource "aws_route_table_association" "private" {
  count          = length(var.vpc.private_subnet_cidrs)
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private.id
}
