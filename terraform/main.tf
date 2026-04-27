terraform {
  backend "s3" {
    bucket         = "shorya-terraform-state-123"
    key            = "linux-automation/terraform.tfstate"
    region         = "eu-west-1"
    dynamodb_table = "terraform-locks"
    encrypt        = true
  }
}

provider "aws" {
  region = "eu-west-1"
}

data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_security_group" "web_sg" {
  
  description = "Allow SSH and HTTP"
  name_prefix = "shorya-web-sg-"
  ingress {
    description = "SSH access"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTP access"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "linux_vm" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type = var.instance_type
  key_name                    = "shorya-key"
  vpc_security_group_ids      = [aws_security_group.web_sg.id]
  associate_public_ip_address = true

  tags = {
  Name = "shorya-${var.environment}-vm"
}
}

output "public_ip" {
  value = aws_instance.linux_vm.public_ip
}

output "ssh_command" {
  value = "ssh -i ~/shorya-key.pem ubuntu@${aws_instance.linux_vm.public_ip}"
}
