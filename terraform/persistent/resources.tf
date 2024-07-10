variable "resources" {
  type = object({
    secret = optional(map(
      object({
        arn  = optional(string)
        name = optional(string)
      })
    ), {})

    # @TODO
    # dynamodb = optional(map(object({ arn = string, id = string })), {})
    # appconfig = optional(object({
    #   application_id         = string,
    #   configuration_profiles = map(object({ configuration_profile_id = string })),
    #   environments           = map(object({ environment_id = string }))
    # }))
    # eventbridge = optional(map(object({ arn = string, id = string })), {})
    # ssm_parameter = optional(map(object({ arn = string })), {})
    # s3            = optional(map(object({ arn = string, id = string })), {})
    # sqs = optional(map(object({
    #   queue = object({ name = optional(string), name_prefix = optional(string), arn = string, url = string, kms_master_key_id = string, visibility_timeout_seconds = number })
    #   dlq   = optional(object({ name = optional(string), name_prefix = optional(string), arn = string, url = string, kms_master_key_id = string, visibility_timeout_seconds = number }))
    # })), {})
  })
  default = {}

  description = "The resources that can possibly be used by the functions."
}