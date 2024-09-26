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

locals {
  sqs_monitoring_defaults = {
    dlq = {
      approximatenumberofmessagesvisible = {
        static  = {
          minimum = {
            enabled = true
          }
        }
      }
    }
  }
  sqs_monitoring = {
    for name, config in module.config_sqs.sqs_config : name => {
      for type in ["queue", "dlq"] : type => {
        for metric, values in {
          for metric in distinct(concat(
            keys(try(local.sqs_monitoring_defaults[type], {})),
            keys(try(local.config.monitoring.sqs[type], {})),
            # keys(try(local.config.stack.http_api.monitoring.route, {})),
            keys(try(config.monitoring[type], {}))
          )) : metric => {
            for subtype in ["static", "anomaly"] : subtype => {
              for statistic, values in {
                for statistic in distinct(concat(
                  keys(try(local.sqs_monitoring_defaults[type][metric][subtype], {})),
                  keys(try(local.config.monitoring.sqs[type][metric][subtype], {})),
                  # keys(try(local.config.stack.http_api.monitoring.route[type][subtype], {})),
                  keys(try(config.monitoring[type][metric][subtype], {}))
                )) :
                statistic => merge(
                  try({ for k, v in local.sqs_monitoring_defaults[type][metric][subtype][statistic] : k => v if v != null }, {}),
                  try({ for k, v in local.config.monitoring.sqs[type][metric][subtype][statistic] : k => v if v != null }, {}),
                  # try({ for k, v in local.config.stack.http_api.monitoring.route[type][subtype][statistic] : k => v if v != null }, {}),
                  try({ for k, v in config.monitoring[type][metric][subtype][statistic] : k => v if v != null }, {})
                )
              } : statistic => values if length(values) > 0
            }
          }
        }: lower(metric) => values if length(values) > 0
      }
    }
  }
}

module "sqs_dlq_monitoring" {
  source = "../modules/aws-cw-alarms-sqs"

  for_each = {
    for key, value in module.sqs : key => value if value.dlq != null
  }

  name   = each.value.dlq.name
  name_prefix = each.value.dlq.name_prefix
  type = "dlq"
  monitoring = try(local.sqs_monitoring[each.key].dlq, {})
  alarm_actions = try(local.config.monitoring.actions.alarm, [])
  ok_actions    = try(local.config.monitoring.actions.ok, [])
}

module "sqs_monitoring" {
  source = "../modules/aws-cw-alarms-sqs"

  for_each = module.sqs

  name   = each.value.queue.name
  name_prefix = each.value.queue.name_prefix
  monitoring = try(local.sqs_monitoring[each.key].queue, {})
  alarm_actions = try(local.config.monitoring.actions.alarm, [])
  ok_actions    = try(local.config.monitoring.actions.ok, [])
}

# output "sqs" {
#   value = module.sqs
# }
