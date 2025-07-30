provider "aws" {
    alias  = "central"
  region = "eu-central-1"
}

# Generate a key pair
resource "tls_private_key" "ec2_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}


resource "aws_key_pair" "deployer" {
  key_name   = "ec2-key"
  public_key = tls_private_key.ec2_key.public_key_openssh
}

# Save private key locally
resource "local_file" "private_key" {
  filename = "${path.module}/ec2-key.pem"
  content  = tls_private_key.ec2_key.private_key_pem
  file_permission = "0400"
}

resource "aws_instance" "web_test" {
  ami           = "ami-0af9b40b1a16fe700"
  instance_type = "t2.micro"
  key_name      = aws_key_pair.deployer.key_name
}

resource "aws_security_group" "ssh_access" {
  name   = "allow_ssh"
  vpc_id = "vpc-093f63f55e5487353" # Replace with your VPC ID

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Allow from anywhere (use cautiously)
  }
}

output "instance_public_ip" {
  value = aws_instance.web_test.public_ip
}
