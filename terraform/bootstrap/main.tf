module "common" {
  source = "../modules/_common"

  config = local.starchart.config

  default_tags = {}
}

locals {
  config = module.common.config
}
