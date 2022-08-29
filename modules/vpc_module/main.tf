resource "aws_vpc" "pro_vpc" {
  cidr_block = var.vpc_cidr

  tags = {
    Name = "pro_vpc"
  }
}

resource "aws_internet_gateway" "pro_igw" {
  vpc_id = aws_vpc.pro_vpc.id

  tags = {
    Name = "pro_igw"
  }
}

resource "aws_subnet" "subnet" {
  count             = length(var.availability_zone)
  vpc_id            = aws_vpc.pro_vpc.id
  cidr_block        = var.subnets[count.index]
  availability_zone = var.availability_zone[count.index]

  tags = {
    Name = "pro_sub${count.index + 1}"
  }
}

resource "aws_route_table" "pro_rt" {
  vpc_id = aws_vpc.pro_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.pro_igw.id
  }

  tags = {
    Name = "pro_rt"
  }
}

resource "aws_route_table_association" "pro_rtass" {
  count          = length(var.availability_zone)
  subnet_id      = element(aws_subnet.subnet.*.id, count.index)
  route_table_id = aws_route_table.pro_rt.id
}
