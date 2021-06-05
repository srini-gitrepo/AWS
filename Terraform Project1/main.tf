provider "aws" {
  region = "us-east-1"
  access_key = "access key will go here"
  secret_key = "access secret key will go here"
}

resource "aws_instance" "my-first-terraform-server" {
  ami = "ami-09e67e426f25ce0d7"
  instance_type = "t2.micro"

  tags = {
    "Name" = "ubuntu"
  }
}