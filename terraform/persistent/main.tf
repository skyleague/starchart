variable "starchart" {
  type = object({

    default_tags   = map(string)
    aws_account_id = string
    aws_region     = string
    bootstrap = object({
      eventing_kms_key_arn      = string
      appconfig_application_id  = string
      appconfig_application_arn = string
    })
    config = any
  })
}

module "common" {
  source = "../../modules/_common"

  config       = var.starchart.config
  default_tags = var.starchart.default_tags
}

locals {
  bootstrap = var.starchart.bootstrap
  config    = module.common.config
}
