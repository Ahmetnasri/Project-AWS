# Server region
variable "aws_region" {
  description = "Set AWS Server"
  default = "eu-central-1"
}

# Bucket name
variable "s3_bucket_name" {
  description = "Name of the S3 bucket"
  default = "ahmets3bucket"
}
