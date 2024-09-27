variable "monitoring" {
  description = "The monitoring configuration for the Lambda"
  type = map(object({
    static  = optional(map(object({
      enabled            = optional(bool)
      threshold          = optional(number)
      period             = optional(number)
      evaluation_periods = optional(number)
      datapoints_to_alarm = optional(number)
    })))
    anomaly = optional(map(object({
      enabled                        = optional(bool)
      evaluation_periods             = optional(number)
      datapoints_to_alarm            = optional(number)
      band_width_standard_deviations = optional(number)
      metric_period                  = optional(number)
    })))
  }))
}

variable "alarm_actions" {
  type        = list(string)
  default     = []
  description = "List of ARNs to notify when the alarm goes to ALARM state"
}

variable "ok_actions" {
  type        = list(string)
  default     = []
  description = "List of ARNs to notify when the alarm returns to OK state"
}

resource "aws_cloudwatch_metric_alarm" "api_static_alarms" {
  for_each = merge([
    for metric, config in var.monitoring : {
      for statistic, details in try(config.static, {}) :
      "${metric} ${statistic}" => merge(
        lookup(
          lookup(local.default_static_values, metric, {}),
          lower(statistic),
          local.default_static_value
        ),
        {
          for key, value in details : key => value
          if value != null
        },
        {
          metric_name = lookup(local.aws_metric_name_mapping, metric, metric)
          statistic   = lookup(local.statistic_mapping, statistic, statistic)
          unit        = lookup(local.unit_mapping, metric, null)
        }
      ) if try(details.enabled, false)
    }
  ]...)

  alarm_name          = "Lambda ${title(each.key)} > ${each.value.threshold}${each.value.unit == "Milliseconds" ? "ms" : ""}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = each.value.evaluation_periods
  datapoints_to_alarm = each.value.datapoints_to_alarm
  metric_name         = each.value.metric_name
  namespace           = "AWS/Lambda"
  period              = each.value.period
  threshold           = each.value.threshold
  alarm_description   = "Auto-generated alarm for Lambda ${each.key}"
  statistic           = length(regexall("[0-9]", each.value.statistic)) == 0 ? each.value.statistic : null
  extended_statistic  = length(regexall("[0-9]", each.value.statistic)) > 0 ? each.value.statistic : null
  alarm_actions       = var.alarm_actions
  ok_actions          = var.ok_actions

  treat_missing_data = "notBreaching"
  unit               = each.value.unit
}

resource "aws_cloudwatch_metric_alarm" "api_anomaly_alarms" {
  for_each = merge([
    for metric, config in var.monitoring : {
      for statistic, details in try(config.anomaly, {}) :
      "${metric} ${statistic}" => merge(
        lookup(
          lookup(local.default_anomaly_values, metric, {}),
          "anomaly",
          local.default_anomaly_value
        ),
        {
          for key, value in details : key => value
          if value != null
        },
        {
          metric_name = lookup(local.aws_metric_name_mapping, metric, metric)
          unit        = lookup(local.unit_mapping, metric, null)
          statistic   = lookup(local.statistic_mapping, statistic, statistic)
        }
      ) if try(details.enabled, false)
    }
  ]...)
  
  alarm_name          = "Lambda ${title(each.key)} Anomaly (${each.value.band_width_standard_deviations} std dev)"
  comparison_operator = "GreaterThanUpperThreshold"
  evaluation_periods  = each.value.evaluation_periods
  datapoints_to_alarm = each.value.datapoints_to_alarm
  threshold_metric_id = "ad1"
  alarm_description   = "Auto-generated alarm for Lambda ${each.key} anomaly (${each.value.band_width_standard_deviations} standard deviations)"
  alarm_actions       = var.alarm_actions
  ok_actions          = var.ok_actions

  metric_query {
    id          = "ad1"
    expression  = "ANOMALY_DETECTION_BAND(m1, ${each.value.band_width_standard_deviations})"
    label       = "${title(each.key)} (Expected)"
    return_data = "true"
  }

  metric_query {
    id = "m1"
    return_data = "true"
    metric {
      metric_name = each.value.metric_name
      namespace   = "AWS/Lambda"
      period      = each.value.metric_period
      stat        = each.value.statistic
      # unit        = lookup(local.unit_mapping, each.value.unit, each.value.unit)
    }
  }
}
