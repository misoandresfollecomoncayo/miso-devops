variable "aws_region" {
    description = "La región de AWS donde se desplegarán los recursos."
    type        = string
}

variable "owner" {
    description = "Propietario de los recursos, generalmente el nombre del usuario o equipo."
    type        = string
}

variable "personal-access-token-github" {
    type = string
    sensitive = true
}