provider "aws" {
    alias  = "central"
  region = var.aws_region
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
  ami           = var.ec2_ami
  instance_type = var.instance_type
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


resource "aws_cloudfront_distribution" "cdn" {
  origin {
    domain_name = aws_instance.web_test.public_dns 
    origin_id   = "EC2Origin"

    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "http-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }
  }

  enabled             = true
  default_root_object = "index.html"

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "EC2Origin"

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "redirect-to-https"
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }
}


output "cloudfront_url" {
  description = "CloudFront Distribution Domain Name"
  value       = aws_cloudfront_distribution.cdn.domain_name
}


output "instance_public_ip" {
  value = aws_instance.web_test.public_ip
}
