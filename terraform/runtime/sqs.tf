module "config_sqs" {
  source = "../modules/config-sqs"

  functions_dir = "${local.starchart.config.repo_root}/${module.lambda_settings.functions_dir}"
  handler_file  = module.lambda_settings.handler_file

  eventbridge_kms_key_id = local.starchart.bootstrap.eventing_kms_key_arn
  persistent_queues      = local.starchart.persistent.sqs
}

module "sqs" {
  source = "git::https://github.com/skyleague/aws-sqs.git?ref=v2.0.0"

  for_each = module.config_sqs.sqs_config

  name_prefix = each.value.name_prefix
  name        = each.value.name

  # Settings with custom defaults
  visibility_timeout_seconds = try(each.value.visibility_timeout_seconds, null)
  message_retention_seconds  = try(each.value.message_retention_seconds, null)
  kms_master_key_id          = try(each.value.kms_master_key_id, local.starchart.bootstrap.eventing_kms_key_arn)

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

resource "aws_cloudwatch_metric_alarm" "sqs_dlq" {
  for_each = {
    for key, value in module.sqs : key => value if value.dlq != null
  }

  alarm_name  = "${each.value.dlq.name_prefix}-messages-available"
  namespace   = "AWS/SQS"
  metric_name = "ApproximateNumberOfMessagesVisible"
  dimensions = {
    QueueName = each.value.dlq.name
  }

  period              = 60
  datapoints_to_alarm = 1
  evaluation_periods  = 1
  statistic           = "Minimum"
  comparison_operator = "GreaterThanThreshold"
  threshold           = 0
  treat_missing_data  = "notBreaching"

  alarm_actions = try([local.starchart.bootstrap.chatbot.sns_notication_arn], [])
  ok_actions    = try([local.starchart.bootstrap.chatbot.sns_notication_arn], [])
}

module "sqs_trigger" {
  source = "git::https://github.com/skyleague/aws-lambda-sqs-trigger.git?ref=v2.0.1"

  for_each = module.config_lambda.sqs_triggers

  sqs        = local.resources.sqs_queue[each.key]
  lambda     = module.lambda[each.value.function_id].lambda
  batch_size = coalesce(each.value.batch_size, 1)
}

module "eventbridge_sqs" {
  source = "../modules/eventbridge-sqs"

  eventbridge_to_sqs = module.config_lambda.eventbridge_to_sqs
  sqs                = module.sqs
  # eventbridge_kms_key_id = var.eventbridge.kms_master_key_id
}

# output "sqs" {
#   value = module.sqs
# }
