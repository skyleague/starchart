variable "function_alarms" {
  type = map(map(object({
      static = map(object({
        enabled            = optional(bool, false)
        threshold          = optional(number)
        period             = optional(number)
        datapoints_to_alarm = optional(number)
        evaluation_periods = optional(number)
      }))
      anomaly = optional(map(object({
        enabled = optional(bool, false)
        evaluation_periods = optional(number)
        datapoints_to_alarm = optional(number)
        band_width_standard_deviations = optional(number)
        metric_period = optional(number)
      })), {})
    })))
  description = "Map of alarms to create, with keys being the resource name"
}

resource "aws_cloudwatch_metric_alarm" "function_static_metric_alarms" {
  for_each = {
      for alarm in flatten([
        for k, v in var.function_alarms : [
          for metric_name, metric_config in v : [
            for statistic, config in metric_config.static : {
              key       = "${k}-${metric_name}-${statistic}"
              metric_name = metric_name
              statistic = lower(statistic)
              function_name = k
              config    = merge(
                lookup(
                  lookup(local.default_static_values, metric_name, {}),
                  lower(statistic),
                  local.default_static_value
                ),
                {
                  for key, value in config : key => value
                  if value != null
                }
              )
              cloudwatch_statistic = lookup(local.statistic_mapping, lower(statistic), statistic)
          } if config.enabled
        ]
      ]
    ]) : alarm.key => alarm
  }

  alarm_name          = "Lambda ${each.value.function_name} : ${each.value.metric_name} ${each.value.statistic} > ${each.value.config.threshold}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = each.value.config.evaluation_periods
  metric_name         = lookup(local.aws_metric_name_mapping, each.value.metric_name, each.value.metric_name)
  namespace           = "AWS/Lambda"
  period              = each.value.config.period
  threshold           = each.value.config.threshold
  alarm_description   = "Auto-generated alarm for Lambda ${each.value.metric_name} ${each.value.statistic}"
  alarm_actions       = var.alarm_actions
  ok_actions          = var.ok_actions

  dimensions = {
    Resource     = each.value.function_name
    FunctionName = each.value.function_name
  }

  treat_missing_data = "notBreaching"
  unit               = lookup(local.unit_mapping, each.value.metric_name, null)

  statistic           = contains(keys(local.statistic_mapping), each.value.statistic) ? each.value.cloudwatch_statistic : null
  extended_statistic  = contains(keys(local.statistic_mapping), each.value.statistic) ? null : each.value.statistic
}

resource "aws_cloudwatch_metric_alarm" "function_anomaly_metric_alarms" {
  for_each = {
    for alarm in flatten([
      for k, v in var.function_alarms : [
        for metric_name, metric_config in v : [
          for statistic, config in metric_config.anomaly : {
            key       = "${k}-${metric_name}-${statistic}-anomaly"
            metric_name = metric_name
            statistic = lower(statistic)
            function_name = k
            config    = merge(
              lookup(
                lookup(local.default_anomaly_values, metric_name, {}),
                "anomaly",
                local.default_anomaly_value
              ),
              {
                for key, value in config : key => value
                if value != null
              }
            )
            cloudwatch_statistic = lookup(local.statistic_mapping, lower(statistic), statistic)
          } if config.enabled
        ]
      ]
    ]) : alarm.key => alarm
  }

  alarm_name          = "Lambda ${each.value.function_name} : ${each.value.metric_name} ${each.value.statistic} Anomaly"
  comparison_operator = "GreaterThanUpperThreshold"
  evaluation_periods  = each.value.config.evaluation_periods
  datapoints_to_alarm = each.value.config.datapoints_to_alarm
  threshold_metric_id = "e1"
  alarm_description   = "Auto-generated anomaly detection alarm for Lambda ${each.value.metric_name} ${each.value.statistic}"
  alarm_actions       = var.alarm_actions
  ok_actions          = var.ok_actions

  metric_query {
    id          = "e1"
    expression  = "ANOMALY_DETECTION_BAND(m1, ${each.value.config.band_width_standard_deviations})"
    label       = "Anomaly Detection Band"
    return_data = "true"
  }

  metric_query {
    id = "m1"
    metric {
      metric_name = lookup(local.aws_metric_name_mapping, each.value.metric_name, each.value.metric_name)
      namespace   = "AWS/Lambda"
      period      = each.value.config.metric_period
      stat        = each.value.cloudwatch_statistic
      unit        = lookup(local.unit_mapping, each.value.metric_name, null)
      dimensions = {
        Resource     = each.value.function_name
        FunctionName = each.value.function_name
      }
    }
    return_data = "true"
  }
}
