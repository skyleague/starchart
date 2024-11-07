locals {
  sqs_triggers = merge([
    for function_id, definition in local.handlers : {
      for idx, _event in try(definition.events, []) : _event.sqs.queueId => {
        function_id = function_id
        batch_size  = try(local.formatted_handlers[function_id].events[idx].sqs.batchSize, null)
      } if try(_event.sqs, null) != null
    }
  ]...)
  eventbridge_to_sqs = merge([
    for function_id, definition in local.handlers : {
      for idx, _event in try(definition.events, []) : _event.sqs.queueId => {
        event_bus_name = try(
          local.formatted_handlers[function_id].events[idx].sqs.eventbridge.eventBusName,
          var.resources.eventbridge[local.formatted_handlers[function_id].events[idx].sqs.eventbridge.eventBusId].id,
          null
        )
        event_pattern = try(jsonencode(local.formatted_handlers[function_id].events[idx].sqs.eventbridge.eventPattern), null)
      } if try(_event.sqs.eventbridge, null) != null
    }
  ]...)
  http_events = flatten([
    for function_id, definition in local.formatted_handlers : [
      for event in try(definition.events, []) : {
        function_name = definition.function_name
        http          = event.http
      } if try(event.http, null) != null
    ]
  ])
  api_definition = {
    for http_path in toset(flatten([for event in local.http_events : event.http.path])) : http_path => {
      for event in local.http_events : upper(event.http.method) => merge(
        {
          function_name = event.function_name
        }, 
        try(event.http.authorizer, null) != null ? { authorizer = event.http.authorizer } : {},
        try(event.http.monitoring, null) != null ? {
          monitoring = {
            for metric, metric_config in try(event.http.monitoring, {}) : metric => {
              static = {
                for statistic, config in try(metric_config.static, {}) : statistic => {
                  for key, value in {
                    enabled            = try(config.enabled, null)
                    threshold          = try(config.threshold, null)
                    period             = try(config.period, null)
                    evaluation_periods = try(config.evaluationPeriods, null)
                    datapoints_to_alarm = try(config.datapointsToAlarm, null)
                  } : key => value if value != null
                } if config != null
              }
              anomaly = {
                for statistic, config in try(metric_config.anomaly, {}) : statistic => {
                  for key, value in {
                    enabled                         = try(config.enabled, null)
                    evaluation_periods              = try(config.evaluationPeriods, null)
                    datapoints_to_alarm             = try(config.datapointsToAlarm, null)
                    band_width_standard_deviations  = try(config.bandWidthStandardDeviations, null)
                    metric_period                   = try(config.metricPeriod, null)
                  } : key => value if value != null
                } if config != null
              }
            }
          }
        } : {}
      ) if event.http.path == http_path
    }
  }
  scheduled_events = merge({
    for function_id, _definition in local.handlers : "lambda-warmer-${_definition.function_name}" => {
      function_name = _definition.function_name
      function_id   = function_id
      schedule = {
        rate        = try(local.formatted_handlers[function_id].warmer.rate, "rate(5 minutes)")
        description = try(local.formatted_handlers[function_id].warmer.description, "Lambda warmer for ${_definition.function_name}")
        input = try(
          local.formatted_handlers[function_id].warmer.input,
          try(_definition.warmer.inputPath, null) == null && try(_definition.warmer.inputTransformer, null) == null
          ? "__WARMER__"
          : null
        )
        inputPath        = try(local.formatted_handlers[function_id].warmer.inputPath, null)
        inputTransformer = try(local.formatted_handlers[function_id].warmer.inputTransformer, null)
      }
    } if try(_definition.warmer.enabled, true) != false
    }, [
    for function_id, _definition in local.handlers : {
      for idx, _event in try(_definition.events, []) : try(_event.ruleNamePrefix, "${function_id}-${idx}") => {
        function_name = _definition.function_name
        function_id   = function_id
        schedule      = local.formatted_handlers[function_id].events[idx].schedule
      } if try(_event.schedule, null) != null
    }
  ]...)
}

output "sqs_triggers" {
  value = local.sqs_triggers
}

output "eventbridge_to_sqs" {
  value = local.eventbridge_to_sqs
}

output "api_definition" {
  value = local.api_definition
}

output "scheduled_events" {
  value = local.scheduled_events
}
