output "bucket_id" {
    value = aws_s3_bucket.web_bucket.id
}

output "bucket_name" {
    value = aws_s3_bucket.web_bucket.bucket
}