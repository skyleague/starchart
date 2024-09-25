variable "starchart" {
  type = object({

    default_tags   = map(string)
    aws_account_id = string
    aws_region     = string
    bootstrap = object({
      eventing_kms_key_arn = string
      appconfig = object({
        application = object({
          id  = string
          arn = string
        })
      })
      chatbot = optional(object({
        sns_notication_arn = string
      }))
    })
    config = any
  })
}

module "common" {
  source = "../modules/_common"

  bootstrap    = var.starchart.bootstrap
  config       = var.starchart.config
  default_tags = var.starchart.default_tags
}

locals {
  bootstrap = var.starchart.bootstrap
  config    = module.common.config
}
