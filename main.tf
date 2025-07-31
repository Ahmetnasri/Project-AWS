# Sets server
provider "aws" {
  region = var.aws_region
}


resource "aws_s3_bucket_policy" "public_policy" {
  bucket = aws_s3_bucket.s3bucket.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "PublicReadGetObject"
        Effect    = "Allow"
        Principal = "*"
        Action    = "s3:GetObject"
        Resource  = "${aws_s3_bucket.s3bucket.arn}/*"
      }
    ]
  })
}

# Creats the bucket
resource "aws_s3_bucket" "s3bucket" {
  bucket = var.s3_bucket_name 


  tags = {
    Name        = "StaticWebsite"
    Environment = "Dev"
  }

}


resource "aws_s3_bucket_public_access_block" "allow_public" {
  bucket = aws_s3_bucket.s3bucket.id

  block_public_acls   = false
  block_public_policy = false
  ignore_public_acls  = false
  restrict_public_buckets = false
}


# 2. Configure static website hosting (NEW resource)
resource "aws_s3_bucket_website_configuration" "website_config" {
  bucket = aws_s3_bucket.s3bucket.id

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "error.html"
  }
}




#  Upload index.html
resource "aws_s3_object" "index" {
  bucket = aws_s3_bucket.s3bucket.id
  key    = "index.html"
  source = "${path.module}/index.html"
  content_type = "text/html"
}

# Upload error.html
resource "aws_s3_object" "error" {
  bucket = aws_s3_bucket.s3bucket.id
  key    = "error.html"
  source = "${path.module}/error.html"
  content_type = "text/html"
}



output "index_html_url" {
  description = "Direct HTTPS URL to index.html"
  value       = "https://${aws_s3_bucket.s3bucket.bucket}.s3.${var.aws_region}.amazonaws.com/index.html"
}


resource "aws_cloudfront_distribution" "cdn" {
  origin {
    domain_name = aws_s3_bucket.s3bucket.bucket_regional_domain_name
    origin_id   = "s3-origin"

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
    target_origin_id = "s3-origin"

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
