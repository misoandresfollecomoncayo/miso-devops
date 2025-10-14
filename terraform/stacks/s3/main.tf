provider "aws" {
    region = var.region
}

resource "aws_s3_bucket" "web_bucket" {
    bucket = var.bucket_name

website {
    index_document = "index.html"
    error_document = "error.html"
}

tags = {
    Name        = "eksState"
    Environment = "Prod"
}
}