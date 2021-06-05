provider "aws" {
  region = "us-east-1"
  access_key = "AKIA3OIRPQFVMFSQHSOF"
  secret_key = "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"
}

resource "aws_instance" "my-first-terraform-server" {
  ami = "ami-09e67e426f25ce0d7"
  instance_type = "t2.micro"

  tags = {
    "Name" = "ubuntu"
  }
}