variable "sqs" {
  type = map(object({
    name                       = optional(string)
    name_prefix                = optional(string)
    visibility_timeout_seconds = optional(number, 60)
    max_message_size           = optional(number)
    delay_seconds              = optional(number, 0)
    message_retention_seconds  = optional(number, 1209600)
    receive_wait_time_seconds  = optional(number)

    policy = optional(any)

    kms_master_key_id                 = optional(string, "alias/aws/sqs")
    kms_data_key_reuse_period_seconds = optional(any)

    tags = optional(map(string), {})

    fifo_settings = optional(any)
    dlq_settings  = optional(any, { enabled = true })
  }))

  description = "The custom configuration for the SQS queues."
  default     = {}
}

module "sqs" {
  source   = "https://github.com/skyleague/aws-sqs.git?ref=v2.0.0"
  for_each = var.sqs

  name_prefix = try(coalesce(each.value.name_prefix, each.value.name == null ? each.key : null), null)
  name        = each.value.name

  # Settings with custom defaults
  visibility_timeout_seconds = try(each.value.visibility_timeout_seconds, null)
  message_retention_seconds  = try(each.value.message_retention_seconds, null)
  kms_master_key_id          = try(each.value.kms_master_key_id, var.starchart.bootstrap.eventing_kms_key_arn)

  # Settings with no custom defaults
  max_message_size                  = try(each.value.max_message_size, null)
  delay_seconds                     = try(each.value.delay_seconds, null)
  receive_wait_time_seconds         = try(each.value.receive_wait_time_seconds, null)
  policy                            = try(each.value.policy, null)
  kms_data_key_reuse_period_seconds = try(each.value.kms_data_key_reuse_period_seconds, null)
  tags                              = try(each.value.tags, null)

  # FIFO settings and DLQ settings
  fifo_settings = try(each.value.fifo_settings, null)
  dlq_settings  = try(each.value.dlq_settings, null)
}

output "sqs" {
  value = module.sqs
}
