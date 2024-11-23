# Criação da VPC
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "main-vpc"
  }
}

# Criação das Subnets Públicas
resource "aws_subnet" "public_az1" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true
  tags = {
    Name = "public_az1"
  }
}

resource "aws_subnet" "public_az2" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "us-east-1b"
  map_public_ip_on_launch = true
  tags = {
    Name = "public_az2"
  }
}

# Criação das Subnets Privadas
resource "aws_subnet" "private_az1" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.3.0/24"
  availability_zone = "us-east-1a"
  tags = {
    Name = "private_az1"
  }
}

resource "aws_subnet" "private_az2" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.4.0/24"
  availability_zone = "us-east-1b"
  tags = {
    Name = "private_az2"
  }
}

# Internet Gateway para a VPC
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "igw-app"
  }
}

# Tabela de Roteamento para Subnets Públicas
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = {
    Name = "internet-route"
  }
}

# Associação de Tabela de Roteamento com as Subnets Públicas
resource "aws_route_table_association" "public_association_az1" {
  subnet_id      = aws_subnet.public_az1.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_route_table_association" "public_association_az2" {
  subnet_id      = aws_subnet.public_az2.id
  route_table_id = aws_route_table.public_rt.id
}

# Elastic IP e NAT Gateway
resource "aws_eip" "nat_eip_az1" {
  domain = "vpc"
  tags = {
    Name = "az1-elastic-ip"
  }
}

resource "aws_eip" "nat_eip_az2" {
  domain = "vpc"
  tags = {
    Name = "az2-elastic-ip"
  }
}

resource "aws_nat_gateway" "nat_az1" {
  allocation_id = aws_eip.nat_eip_az1.id
  subnet_id     = aws_subnet.public_az1.id
}

resource "aws_nat_gateway" "nat_az2" {
  allocation_id = aws_eip.nat_eip_az2.id
  subnet_id     = aws_subnet.public_az2.id
}

# Tabelas de Roteamento para Subnets Privadas
resource "aws_route_table" "private_rt_az1" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_az1.id
  }

  tags = {
    Name = "private_rt_az1"
  }
}

resource "aws_route_table" "private_rt_az2" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_az2.id
  }

  tags = {
    Name = "private_rt_az2"
  }
}

resource "aws_route_table_association" "private_association_az1" {
  subnet_id      = aws_subnet.private_az1.id
  route_table_id = aws_route_table.private_rt_az1.id
}

resource "aws_route_table_association" "private_association_az2" {
  subnet_id      = aws_subnet.private_az2.id
  route_table_id = aws_route_table.private_rt_az2.id
}
