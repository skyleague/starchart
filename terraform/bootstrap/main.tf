module "common" {
  source = "../../modules/_common"

  config = {
    project_name       = var.starchart.config.project_name
    project_identifier = var.starchart.config.project_identifier
    environment        = var.starchart.config.environment
    stack              = var.starchart.config.stack
    domain             = var.starchart.config.domain
    repo_root          = var.starchart.config.repo_root
  }

  default_tags = {}
}

locals {
  config = module.common.config
}
