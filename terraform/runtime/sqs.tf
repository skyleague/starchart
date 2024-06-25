variable "sqs" {
  type = object({
    queue_settings = optional(map(any))

    visibility_timeout_seconds = optional(number, 30)
    max_message_size           = optional(number)
    delay_seconds              = optional(number, 0)
    message_retention_seconds  = optional(number, 1209600)
    receive_wait_time_seconds  = optional(number)

    policy = optional(any)

    kms_master_key_id                 = optional(string)
    kms_data_key_reuse_period_seconds = optional(any)

    tags = optional(map(string), {})

    fifo_settings = optional(any)
    dlq_settings  = optional(any, { enabled = true })
    batch_size    = optional(number, 1)
  })

  description = "The custom configuration for the SQS queues."
  default     = {}
}

module "config_sqs" {
  source = "../../modules/config-sqs"

  functions_dir = local.functions_dir

  eventbridge_kms_key_id = var.starchart.bootstrap.eventing_kms_key_arn
  queue_settings         = var.sqs.queue_settings
}

module "sqs" {
  source = "git@github.com:skyleague/aws-sqs.git?ref=v2.0.0"

  for_each = module.config_sqs.sqs_config

  name_prefix = each.value.name_prefix
  name        = each.value.name

  # Settings with custom defaults
  visibility_timeout_seconds = try(coalesce(each.value.visibility_timeout_seconds, var.sqs.visibility_timeout_seconds), null)
  message_retention_seconds  = try(coalesce(each.value.message_retention_seconds, var.sqs.message_retention_seconds), null)
  kms_master_key_id          = try(each.value.kms_master_key_id, var.sqs.kms_master_key_id, var.starchart.bootstrap.eventing_kms_key_arn)

  # Settings with no custom defaults
  max_message_size                  = try(coalesce(each.value.max_message_size, var.sqs.max_message_size), null)
  delay_seconds                     = try(coalesce(each.value.delay_seconds, var.sqs.delay_seconds), null)
  receive_wait_time_seconds         = try(coalesce(each.value.receive_wait_time_seconds, var.sqs.receive_wait_time_seconds), null)
  policy                            = try(coalesce(each.value.policy, var.sqs.policy), null)
  kms_data_key_reuse_period_seconds = try(coalesce(each.value.kms_data_key_reuse_period_seconds, var.sqs.kms_data_key_reuse_period_seconds), null)
  tags                              = try(coalesce(each.value.tags, var.sqs.tags), null)

  # FIFO settings and DLQ settings
  fifo_settings = try(coalesce(each.value.fifo, var.sqs.fifo_settings), null)
  dlq_settings  = try(coalesce(each.value.dlq, var.sqs.dlq_settings), null)
}

module "sqs_trigger" {
  source = "git@github.com:skyleague/aws-lambda-sqs-trigger.git?ref=v2.0.0"

  for_each = module.config_lambda.sqs_triggers

  sqs        = module.sqs[each.key].queue
  lambda     = module.lambda[each.value.function_id].lambda
  batch_size = coalesce(each.value.batch_size, var.sqs.batch_size, 1)
}

module "eventbridge_sqs" {
  source = "../../modules/eventbridge-sqs"

  eventbridge_to_sqs = module.config_lambda.eventbridge_to_sqs
  sqs                = module.sqs
  # eventbridge_kms_key_id = var.eventbridge.kms_master_key_id
}

# output "sqs" {
#   value = module.sqs
# }
