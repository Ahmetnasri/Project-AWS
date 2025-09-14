# Server region
variable "aws_region" {
  description = "Set AWS Server"
  default = "eu-central-1"
}

# ami of ec2
variable "ec2_ami" {
  description = "AMI ID of the EC2"
  default = "ami-0af9b40b1a16fe700"
}

# EC2 Instance Type
variable "instance_type" {
  description = "Type of the EC2 Instance"
  default = "t2.micro"
}
