variable "bucket_name" {
    type = string
}

variable "index_document" {
    type    = string
    default = "index.html"
}

variable "error_document" {
    type    = string
    default = "error.html"
}

variable "environment" {
    type = string
}
