module "config_sqs" {
  source = "../../modules/config-sqs"

  functions_dir = local.functions_dir

  eventbridge_kms_key_id = var.starchart.bootstrap.eventing_kms_key_arn
  persistent_queues      = var.starchart.persistent.sqs
}

module "sqs" {
  source = "git@github.com:skyleague/aws-sqs.git?ref=v2.0.0"

  for_each = module.config_sqs.sqs_config

  name_prefix = each.value.name_prefix
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
  fifo_settings = try(each.value.fifo, null)
  dlq_settings  = try(each.value.dlq, null)
}

module "sqs_trigger" {
  source = "git@github.com:skyleague/aws-lambda-sqs-trigger.git?ref=v2.0.0"

  for_each = module.config_lambda.sqs_triggers

  sqs        = local.resources.sqs_queue[each.key]
  lambda     = module.lambda[each.value.function_id].lambda
  batch_size = coalesce(each.value.batch_size, 1)
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
