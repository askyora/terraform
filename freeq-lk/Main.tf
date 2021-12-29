# Configure the AWS Provider
provider "aws" {
  region     = "${REGION}"
  access_key = "${ACCESS_KEY}"
  secret_key = "${SECRET_KEY}"
}
resource "aws_instance" "freeq-lk" {
  ami           = "ami-01581ffba3821cdf3"
  instance_type = "t2.micro"
  key_name = "freeq_aws_terraform"
}

resource "aws_key_pair" "freeq_aws_terraform"  {
  key_name = "freeq_aws_terraform"
  public_key = "${file("~/.ssh/freeq_aws_terraform.pem.pub")}"
}

# Create a VPC
resource "aws_vpc" "freeq-lk-vpc" {
  cidr_block       = "10.0.0.0/16"
  instance_tenancy = "default"
  tags = {
    Name = "freeq-lk-vpc"
  }
}

resource "aws_internet_gateway" "freeq-lk-gw" {
  vpc_id = aws_vpc.freeq-lk-vpc.id
}

resource "aws_route_table" "freeq-lk-route-table" {
  vpc_id = aws_vpc.freeq-lk-vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.freeq-lk-gw.id
  }

  route {
    ipv6_cidr_block        = "::/0"
    gateway_id = aws_internet_gateway.freeq-lk-gw.id
  }
}

resource "aws_subnet" "freeq-lk-subnet" {
  vpc_id            = aws_vpc.freeq-lk-vpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "ap-southeast-1a"
  tags = {
    "Name" = "freeq-lk-subnet"
  }
}

resource "aws_route_table_association" "freeq-table-association" {
    subnet_id = aws_subnet.freeq-lk-subnet.id
    route_table_id = aws_route_table.freeq-lk-route-table.id
}

resource "aws_security_group" "freeq-lk-web-allow" { 
  name        = "freeq-lk-web-allow"
  description = "Allow web inbound traffic"
  vpc_id      = aws_vpc.freeq-lk-vpc.id

  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
 ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
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
    Name = "freeq-lk-web-allow"
  }
}


resource "aws_network_interface" "freeq-lk-ni" {
  subnet_id       = aws_subnet.freeq-lk-subnet.id
  private_ips     = ["10.0.1.50"]
  security_groups = [aws_security_group.freeq-lk-web-allow.id]
}

resource "aws_db_instance" "default" {
  allocated_storage    = 20
  engine               = "mysql"
  engine_version       = "8.0.20"
  instance_class       = "db.t2.micro"
  name                 = "freeqlk"
  username             = "admin"
  password             = "9b4ef17157ab4e2a"
  parameter_group_name = "default.mysql8.0"
  publicly_accessible  = true
  skip_final_snapshot  = true
}