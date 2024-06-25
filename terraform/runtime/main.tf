variable "starchart" {
  type = object({

    default_tags   = map(string)
    aws_account_id = string
    aws_region     = string
    bootstrap = object({
      eventing_kms_key_arn      = string
      artifacts_bucket_id       = string
      appconfig_application_id  = string
      appconfig_application_arn = string
    })
    config = any
    persistent = optional(object({
      dynamodb = optional(map(object({ arn = string, id = string })), {})
      appconfig = optional(object({
        configuration_profiles = map(object({ configuration_profile_id = string })),
        environments           = map(object({ environment_id = string }))
      }))
      eventbridge = optional(map(object({ arn = string, id = string })), {})

      # check
      secrets        = optional(map(object({ arn = string })), {})
      ssm_parameters = optional(map(object({ arn = string })), {})
      s3             = optional(map(object({ arn = string, id = string })), {})

    }), {})
    stacks = optional(map(object({
      persistent = optional(object({
        dynamodb = optional(map(object({ arn = string, id = string })), {})
        appconfig = optional(object({
          configuration_profiles = map(object({ configuration_profile_id = string })),
          environments           = map(object({ environment_id = string }))
        }))
        eventbridge = optional(map(object({ arn = string, id = string })), {})

        # check
        secrets        = optional(map(object({ arn = string })), {})
        ssm_parameters = optional(map(object({ arn = string })), {})
        s3             = optional(map(object({ arn = string, id = string })), {})
      }), {})
    })), {})
  })
}

module "common" {
  source = "../../modules/_common"

  config       = var.starchart.config
  default_tags = var.starchart.default_tags
}

locals {
  config     = module.common.config
  bootstrap  = var.starchart.bootstrap
  persistent = var.starchart.persistent
}


output "name" {
  value = var.starchart
}
