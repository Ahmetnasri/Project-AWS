# Server region
variable "aws_region" {
  description = "Set AWS Server"
  default = "us-east-1"
}

# ami of ec2
variable "ec2_ami" {
  description = "AMI ID of the EC2"
  default = "ami-0b09ffb6d8b58ca91"
}

# EC2 Instance Type
variable "instance_type" {
  description = "Type of the EC2 Instance"
  default = "t2.micro"
}

# VPC ID
variable "vpc_id" {
  description = "The VPC ID"
  default = "vpc-09e7800659087c48b" # Replace with your VPC ID
}
