variable "api_id" {
  type        = string
  description = "The ID of the API Gateway"
}

variable "api_name" {
  type        = string
  description = "The name of the API Gateway"
}

variable "monitoring" {
  description = "The monitoring configuration for the API Gateway"
  type = object({
    latency   = optional(object({
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
    count_4xx = optional(object({
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
    count_5xx = optional(object({
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
    count     = optional(object({
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
    slo       = optional(object({
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
  })
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
    } if metric != "slo"
  ]...)

  alarm_name          = "API [${var.api_name}] ${title(each.key)} > ${each.value.threshold}${each.value.unit == "Milliseconds" ? "ms" : ""}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = each.value.evaluation_periods
  datapoints_to_alarm = each.value.datapoints_to_alarm
  metric_name         = each.value.metric_name
  namespace           = "AWS/ApiGateway"
  period              = each.value.period
  threshold           = each.value.threshold
  alarm_description   = "Auto-generated alarm for API Gateway ${each.key}"
  statistic           = length(regexall("[0-9]", each.value.statistic)) == 0 ? each.value.statistic : null
  extended_statistic  = length(regexall("[0-9]", each.value.statistic)) > 0 ? each.value.statistic : null
  alarm_actions       = var.alarm_actions
  ok_actions          = var.ok_actions

  dimensions = {
    ApiId = var.api_id
  }

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
    } if metric != "slo"
  ]...)
  
  alarm_name          = "API [${var.api_name}] ${title(each.key)} Anomaly (${each.value.band_width_standard_deviations} std dev)"
  comparison_operator = "GreaterThanUpperThreshold"
  evaluation_periods  = each.value.evaluation_periods
  datapoints_to_alarm = each.value.datapoints_to_alarm
  threshold_metric_id = "ad1"
  alarm_description   = "Auto-generated alarm for API Gateway ${each.key} anomaly (${each.value.band_width_standard_deviations} standard deviations)"
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
      namespace   = "AWS/ApiGateway"
      period      = each.value.metric_period
      stat        = each.value.statistic
      unit        = lookup(local.unit_mapping, each.value.unit, each.value.unit)

      dimensions = {
        ApiId = var.api_id
      }
    }
  }
}

resource "aws_cloudwatch_metric_alarm" "slo_success_rate_static_alarm" {
  for_each = {
    for k, v in { "success_rate" = try(var.monitoring.slo.static.success_rate, {}) } :
    k => merge(local.default_static_values.slo[k], {
      for key, value in v : key => value
      if value != null
    })
    if try(v.enabled, false)
  }

  alarm_name          = "API [${var.api_name}] SLO Breach: Success Rate < ${each.value.threshold}%"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = each.value.evaluation_periods
  threshold           = each.value.threshold
  period              = each.value.period
  alarm_description   = "Auto-generated alarm for API Gateway SLO breach: Success Rate"
  alarm_actions       = var.alarm_actions
  ok_actions          = var.ok_actions

  treat_missing_data = "notBreaching"

  metric_query {
    id          = "e1"
    expression  = "IF(m1 > 0, 100 * (m1 - m2 - m3) / m1, 100)"
    label       = "Success Rate (%)"
    return_data = "true"
  }

  metric_query {
    id = "m1"
    metric {
      metric_name = "Count"
      namespace   = "AWS/ApiGateway"
      period      = each.value.period
      stat        = "Sum"
      dimensions  = { ApiId = var.api_id }
    }
  }

  metric_query {
    id = "m2"
    metric {
      metric_name = "4xx"
      namespace   = "AWS/ApiGateway"
      period      = each.value.period
      stat        = "Sum"
      dimensions  = { ApiId = var.api_id }
    }
  }

  metric_query {
    id = "m3"
    metric {
      metric_name = "5xx"
      namespace   = "AWS/ApiGateway"
      period      = each.value.period
      stat        = "Sum"
      dimensions  = { ApiId = var.api_id }
    }
  }
}

resource "aws_cloudwatch_metric_alarm" "slo_success_rate_anomaly_alarm" {
  for_each = {
    for k, v in { "success_rate" = try(var.monitoring.slo.anomaly.success_rate, {}) } :
    k => merge(local.default_anomaly_values.slo[k], {
      for key, value in v : key => value
      if value != null
    })
    if try(v.enabled, false)
  }
  
  alarm_name          = "API [${var.api_name}] SLO Anomaly: Success Rate (${each.value.band_width_standard_deviations} std dev)"
  comparison_operator = "LessThanLowerThreshold"
  evaluation_periods  = each.value.evaluation_periods
  datapoints_to_alarm = each.value.datapoints_to_alarm
  threshold_metric_id = "ad1"
  alarm_description   = "Auto-generated alarm for API Gateway SLO anomaly: Success Rate (${each.value.band_width_standard_deviations} standard deviations)"
  alarm_actions       = var.alarm_actions
  ok_actions          = var.ok_actions

  treat_missing_data = "notBreaching"

  metric_query {
    id          = "ad1"
    expression  = "ANOMALY_DETECTION_BAND(m1, ${each.value.band_width_standard_deviations})"
    label       = "Success Rate (Expected)"
    return_data = "true"
  }

  metric_query {
    id          = "m1"
    expression  = "100 * (m2 - m3 - m4) / m2"
    label       = "Success Rate (%)"
    return_data = "true"
  }

  metric_query {
    id = "m2"
    metric {
      metric_name = "Count"
      namespace   = "AWS/ApiGateway"
      period      = each.value.metric_period
      stat        = "Sum"
      dimensions  = { ApiId = var.api_id }
    }
  }

  metric_query {
    id = "m3"
    metric {
      metric_name = "4xx"
      namespace   = "AWS/ApiGateway"
      period      = each.value.metric_period
      stat        = "Sum"
      dimensions  = { ApiId = var.api_id }
    }
  }

  metric_query {
    id = "m4"
    metric {
      metric_name = "5xx"
      namespace   = "AWS/ApiGateway"
      period      = each.value.metric_period
      stat        = "Sum"
      dimensions  = { ApiId = var.api_id }
    }
  }
}