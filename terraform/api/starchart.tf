variable "starchart" {
  type = object({
    default_tags   = map(string)
    aws_account_id = string
    aws_region     = string
    config         = any
    stacks = optional(map(object({
      runtime = optional(object({
        deferred_rest_api_input = optional(string)
        deferred_http_api_input = optional(string)
      }), {})
    })), {})
  })
}

locals {
  starchart = var.starchart
}