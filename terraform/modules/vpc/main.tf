resource "aws_vpc" "beanstalk_vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "beanstalk-vpc"
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.beanstalk_vpc.id

  tags = {
    Name = "beanstalk-igw"
  }
}

# Subnets públicas (para ALB)
resource "aws_subnet" "public_subnets" {
  count                   = length(var.public_subnet_cidrs)
  vpc_id                  = aws_vpc.beanstalk_vpc.id
  cidr_block              = var.public_subnet_cidrs[count.index]
  availability_zone       = var.azs[count.index]
  map_public_ip_on_launch = true

  tags = {
    Name = "beanstalk-public-${count.index}"
    "aws:elasticbeanstalk:environment-type" = "LoadBalanced"
  }
}

# Subnets privadas (para EC2)
resource "aws_subnet" "private_subnets" {
  count             = length(var.private_subnet_cidrs)
  vpc_id            = aws_vpc.beanstalk_vpc.id
  cidr_block        = var.private_subnet_cidrs[count.index]
  availability_zone = var.azs[count.index]

  tags = {
    Name = "beanstalk-private-${count.index}"
    "aws:elasticbeanstalk:environment-type" = "LoadBalanced"
  }
}

# NAT EIP
resource "aws_eip" "nat" {
  domain = "vpc"
}

# NAT Gateway (solo 1 para ahorrar)
resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public_subnets[0].id

  tags = {
    Name = "beanstalk-nat"
  }
}

# Route Table Pública
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.beanstalk_vpc.id
}

resource "aws_route" "public_internet" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw.id
}

resource "aws_route_table_association" "public_assoc" {
  count          = length(aws_subnet.public_subnets)
  subnet_id      = aws_subnet.public_subnets[count.index].id
  route_table_id = aws_route_table.public.id
}

# Route Table Privada
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.beanstalk_vpc.id
}

resource "aws_route" "private_nat" {
  route_table_id         = aws_route_table.private.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.nat.id
}

resource "aws_route_table_association" "private_assoc" {
  count          = length(aws_subnet.private_subnets)
  subnet_id      = aws_subnet.private_subnets[count.index].id
  route_table_id = aws_route_table.private.id
}
