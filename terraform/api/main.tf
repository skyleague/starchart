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
    stacks = optional(map(object({
      runtime = optional(object({
        deferred_rest_api_input = optional(string)
        deferred_http_api_input = optional(string)
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
  config    = module.common.config
  bootstrap = var.starchart.bootstrap
}


# output "output" {
#   value = var.starchart
# }
