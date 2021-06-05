provider "aws" {
  region = "us-east-1"
  access_key = "AKIA3OIRPQFVMFSQHSOF"
  secret_key = "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"
}

#1 create a vpc

resource "aws_vpc" "my_vpc" {
  cidr_block = "10.0.0.0/16"
    tags = {
        "Name" = "My_VPC"
    }
}


#2 create internet gateway

resource "aws_internet_gateway" "my_gateway" {
  vpc_id = aws_vpc.my_vpc.id
}

#3 create custom route table

resource "aws_route_table" "my_route_table" {
  vpc_id = aws_vpc.my_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.my_gateway.id
  }

  route {
    ipv6_cidr_block        = "::/0"
    gateway_id = aws_internet_gateway.my_gateway.id
  }

  tags = {
    Name = "My_Route_Table"
  }
}

#4 create a subnet

resource "aws_subnet" "my_subnet" {
  vpc_id     = aws_vpc.my_vpc.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "us-east-1a"

  tags = {
    Name = "My_Subnet"
  }
}

#5 Associate subnet with route table

resource "aws_route_table_association" "my_association" {
  subnet_id      = aws_subnet.my_subnet.id
  route_table_id = aws_route_table.my_route_table.id
}

#6 create a security group to allow port 22,80,443

resource "aws_security_group" "my_security_group" {
  name        = "my_security_group_new"
  description = "Allow web inbound traffic"
  vpc_id      = aws_vpc.my_vpc.id

  ingress {
    description      = "https"
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
  ingress {
    description      = "http"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
  ingress {
    description      = "ssh"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "My_Security_Group"
  }
}

#7 create a network interace with an ip in the subnet that was created in step4

resource "aws_network_interface" "my_network_interface" {
  subnet_id       = aws_subnet.my_subnet.id
  private_ips     = ["10.0.1.50"]
  security_groups = [aws_security_group.my_security_group.id]
}

#8 Assign an elastic IP to the network interface created in step 7

resource "aws_eip" "my_eip" {
  vpc                       = true
  network_interface         = aws_network_interface.my_network_interface.id
  associate_with_private_ip = "10.0.1.50"
  depends_on = [aws_internet_gateway.my_gateway,aws_instance.my-web-server]
}


output "server_public_ip" {
   value = aws_eip.my_eip.public_ip
}

#9 create an ubuntu server and install/enable apache2

resource "aws_instance" "my-web-server" {
  ami = "ami-0747bdcabd34c712a"
  instance_type = "t2.micro"
  availability_zone = "us-east-1a"
  key_name = "main.key"
  network_interface{
    network_interface_id = aws_network_interface.my_network_interface.id
    device_index = 0
  }
  user_data = <<-EOF
              #!/bin/bash
              sudo apt update -y
              sudo apt install apache2 -y
              sudo systemctl start apache2
              sudo bash -c 'echo your very first web server > /var/www/html/index.html'
              EOF

  tags = {
    "Name" = "My-Web-Server"
  }
}

