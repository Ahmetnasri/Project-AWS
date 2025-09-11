output "index_html_url" {
  description = "Direct HTTPS URL to index.html"
  value       = "https://${aws_s3_bucket.s3bucket.bucket}.s3.${var.aws_region}.amazonaws.com/index.html"
}

output "cloudfront_url" {
  description = "CloudFront Distribution Domain Name"
  value       = aws_cloudfront_distribution.cdn.domain_name
}