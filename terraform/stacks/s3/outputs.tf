output "bucket_name" {
    value = aws_s3_bucket.web_bucket.bucket
}

output "bucket_website_url" {
    value = aws_s3_bucket.web_bucket.website_endpoint
}
