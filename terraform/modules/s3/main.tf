resource "aws_s3_bucket" "web_bucket" {
    bucket = var.bucket_name

    website {
    index_document = var.index_document
    error_document = var.error_document
    }

    tags = {
    Environment = var.environment
    }
}
