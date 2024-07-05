variable "starchart" {
  type = object({

    default_tags   = map(string)
    aws_account_id = string
    aws_region     = string
    bootstrap = object({
      eventing_kms_key_arn = string
      artifacts_bucket_id  = string
      appconfig = object({
        application = object({
          id  = string
          arn = string
        })
      })
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
      secret        = optional(map(object({ arn = string })), {})
      ssm_parameter = optional(map(object({ arn = string })), {})
      s3            = optional(map(object({ arn = string, id = string })), {})
      sqs = optional(map(object({
        queue = object({ name = optional(string), name_prefix = optional(string), arn = string, url = string, kms_master_key_id = string, visibility_timeout_seconds = number })
        dlq   = optional(object({ name = optional(string), name_prefix = optional(string), arn = string, url = string, kms_master_key_id = string, visibility_timeout_seconds = number }))
      })), {})

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
        secret        = optional(map(object({ arn = string })), {})
        ssm_parameter = optional(map(object({ arn = string })), {})
        s3            = optional(map(object({ arn = string, id = string })), {})
        sqs = optional(map(object({
          queue = object({ name = optional(string), name_prefix = optional(string), arn = string, url = string, kms_master_key_id = string, visibility_timeout_seconds = number })
          dlq   = optional(object({ name = optional(string), name_prefix = optional(string), arn = string, url = string, kms_master_key_id = string, visibility_timeout_seconds = number }))
        })), {})
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


# output "output" {
#   value = var.starchart
# }
