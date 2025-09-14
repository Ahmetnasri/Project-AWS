# Server region
variable "aws_region" {
  description = "Set AWS Server"
  default = "eu-central-1"
}

# ami of ec2
variable "ec2_ami" {
  description = "Name of the S3 bucket"
  default = "ami-0af9b40b1a16fe700"
}
