
# VPC
resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name = "main-vpc"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "main-igw"
  }
}

# Create two availability zones
data "aws_availability_zones" "available" {}

# Public Subnet 1
resource "aws_subnet" "public_subnet_1" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.10.0/24"  # Adjusted CIDR block
  availability_zone = element(data.aws_availability_zones.available.names, 0)
  map_public_ip_on_launch = true
  tags = {
    Name = "public-subnet-1"
  }
}

# Public Subnet 2
resource "aws_subnet" "public_subnet_2" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.20.0/24"  # Adjusted CIDR block
  availability_zone = element(data.aws_availability_zones.available.names, 1)
  map_public_ip_on_launch = true
  tags = {
    Name = "public-subnet-2"
  }
}

# Private Subnet 1
resource "aws_subnet" "private_subnet_1" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.30.0/24"  # Adjusted CIDR block
  availability_zone = element(data.aws_availability_zones.available.names, 0)
  tags = {
    Name = "private-subnet-1"
  }
}

# Private Subnet 2
resource "aws_subnet" "private_subnet_2" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.40.0/24"  # Adjusted CIDR block
  availability_zone = element(data.aws_availability_zones.available.names, 1)
  tags = {
    Name = "private-subnet-2"
  }
}

# Public Route Table 1
resource "aws_route_table" "public_rt_1" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "public-rt-1"
  }
}

# Public Route Table 2
resource "aws_route_table" "public_rt_2" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "public-rt-2"
  }
}

# Public Route to Internet Gateway (for both public route tables)
resource "aws_route" "public_route_1" {
  route_table_id         = aws_route_table.public_rt_1.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.main.id
}

resource "aws_route" "public_route_2" {
  route_table_id         = aws_route_table.public_rt_2.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.main.id
}

# Associate Public Subnets with Route Tables
resource "aws_route_table_association" "public_assoc_1" {
  subnet_id      = aws_subnet.public_subnet_1.id
  route_table_id = aws_route_table.public_rt_1.id
}

resource "aws_route_table_association" "public_assoc_2" {
  subnet_id      = aws_subnet.public_subnet_2.id
  route_table_id = aws_route_table.public_rt_2.id
}

# NAT Gateway 1
resource "aws_eip" "nat_eip_1" {
  domain = "vpc"
  tags = {
    Name = "nat-eip-1"
  }
}

resource "aws_nat_gateway" "nat_gw_1" {
  allocation_id = aws_eip.nat_eip_1.id
  subnet_id     = aws_subnet.public_subnet_1.id
  tags = {
    Name = "nat-gateway-1"
  }
  depends_on = [aws_internet_gateway.main]
}

# NAT Gateway 2
resource "aws_eip" "nat_eip_2" {
  domain = "vpc"
  tags = {
    Name = "nat-eip-2"
  }
}

resource "aws_nat_gateway" "nat_gw_2" {
  allocation_id = aws_eip.nat_eip_2.id
  subnet_id     = aws_subnet.public_subnet_2.id
  tags = {
    Name = "nat-gateway-2"
  }
  depends_on = [aws_internet_gateway.main]
}

# Private Route Table 1
resource "aws_route_table" "private_rt_1" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "private-rt-1"
  }
}

# Private Route Table 2
resource "aws_route_table" "private_rt_2" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "private-rt-2"
  }
}

# Route for Private Subnets to NAT Gateway
resource "aws_route" "private_route_1" {
  route_table_id         = aws_route_table.private_rt_1.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.nat_gw_1.id
  depends_on             = [aws_nat_gateway.nat_gw_1]
}

resource "aws_route" "private_route_2" {
  route_table_id         = aws_route_table.private_rt_2.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.nat_gw_2.id
  depends_on             = [aws_nat_gateway.nat_gw_2]
}

# Associate Private Subnets with Route Tables
resource "aws_route_table_association" "private_assoc_1" {
  subnet_id      = aws_subnet.private_subnet_1.id
  route_table_id = aws_route_table.private_rt_1.id
}

resource "aws_route_table_association" "private_assoc_2" {
  subnet_id      = aws_subnet.private_subnet_2.id
  route_table_id = aws_route_table.private_rt_2.id
}
