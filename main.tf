#1. Create VPC
resource "aws_vpc" "demo_vpc" {
  cidr_block       = "10.0.0.0/16"
  instance_tenancy = "default"

  tags = {
    Name = "terraform_demo_vpc"
  }
}
#2. Create Internet Gateway
resource "aws_internet_gateway" "demo_gw" {
  vpc_id = aws_vpc.demo_vpc.id

  tags = {
    Name = "terraform_demo_gw"
  }
}
#3. Create Custom Route Table
resource "aws_route_table" "demo_rt" {
  vpc_id = aws_vpc.demo_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.demo_gw.id
  }

  tags = {
    Name = "terraform_demo_rt"
  }
}
#4. Create a Subnet for Web Server
resource "aws_subnet" "subnet_1" {
     vpc_id            = aws_vpc.demo_vpc.id
     cidr_block        = "10.0.1.0/24"

     tags = {
       "name" = "terraform_demo_subnet-1"
     }
   }
#5. Associate Subnet with Route Table
resource "aws_route_table_association" "rt_association" {
  subnet_id      = aws_subnet.subnet_1.id
  route_table_id = aws_route_table.demo_rt.id
}
#6. Create Security Group to allow port 22, 80, 443
resource "aws_security_group" "demo_allow_tls" {
  name        = "allow_tls"
  description = "Allow TLS inbound traffic"
  vpc_id      = aws_vpc.demo_vpc.id

  ingress {
    description      = "TLS from VPC"
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    cidr_blocks      = [aws_vpc.demo_vpc.cidr_block]
  }

  ingress {
    description      = "TLS from VPC"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = [aws_vpc.demo_vpc.cidr_block]
  }

  ingress {
    description      = "TLS from VPC"
    from_port        = 8080
    to_port          = 8080
    protocol         = "tcp"
    cidr_blocks      = [aws_vpc.demo_vpc.cidr_block]
  }

  ingress {
    description      = "TLS from VPC"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = [aws_vpc.demo_vpc.cidr_block]
  }

  tags = {
    Name = "terraform_demo_allow"
  }
}
#7. Create a network interface with an ip in the subnet that was created in step4
resource "aws_network_interface" "hello_interface" {
  subnet_id       = aws_subnet.subnet_1.id
  private_ips     = ["10.0.1.50"]
  security_groups = [aws_security_group.demo_allow_tls.id]
}

#8. Assign an elastic IP to the network interface created in step7
resource "aws_eip_association" "demo_eip_assoc" {
  instance_id   = aws_instance.demo_instance.id
  allocation_id = aws_eip.demo_eip.id
}

#9. Create Ubuntu Server and Install/Enable apache2

resource "aws_instance" "demo_instance" {
  ami               = "ami-0c1a7f89451184c8b"
  instance_type     = "t2.micro"
  key_name          = "demo"

  network_interface {
    device_index         = 1
    network_interface_id = aws_network_interface.hello_interface.id
  }

  user_data = <<-EOF
                !/bin/bash
                sudo apt update -y
                sudo apt install apache2 -y
                sudo systemctl start apache2
                sudo bash -c 'echo Hello Balaraju Golla.. This message is genrated from webserver > /var/www/html/index.html'
                EOF
  tags = {
    Name = "demo_instance"
  }
}

#10. New Elastic IP
resource "aws_eip" "demo_eip" {
  vpc = true
}


