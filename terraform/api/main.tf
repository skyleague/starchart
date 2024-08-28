module "common" {
  source = "../modules/_common"

  config       = local.starchart.config
  default_tags = local.starchart.default_tags
}

locals {
  config = module.common.config
}


# output "output" {
#   value = local.starchart
# }
