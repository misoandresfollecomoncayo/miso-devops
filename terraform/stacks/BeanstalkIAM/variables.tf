variable "rolename" {
    description = "IAMRole Name"
    type        = string
    nullable    = false
}

variable "aws_region" {
    description = "La región de AWS donde se desplegarán los recursos."
    type        = string
}

variable "owner" {
    description = "Propietario de los recursos, generalmente el nombre del usuario o equipo."
    type        = string
}