variable "region" {
    description = "La región de AWS"
    type        = string
    default     = "us-east-1"
}

variable "bucket_name" {
    description = "Nombre del bucket S3"
    type        = string
    default     = "terraform-dann-g13"
}
