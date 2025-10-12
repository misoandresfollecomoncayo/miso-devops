###########################################################
# IAMRole Configuration
###########################################################

module "IAMRole" {
    source = "../../modules/IAMRole"
    rolename = var.rolename
}