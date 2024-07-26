module "common" {
  source = "../modules/_common"

  config = {
    project_name       = local.starchart.config.project_name
    project_identifier = local.starchart.config.project_identifier
    environment        = local.starchart.config.environment
    stack              = local.starchart.config.stack
    repo_root          = local.starchart.config.repo_root
  }

  default_tags = {}
}

locals {
  config = module.common.config
}
