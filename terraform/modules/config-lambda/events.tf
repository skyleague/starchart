locals {
  sqs_triggers = merge([
    for function_id, definition in local.handlers : {
      for event in try(definition.events, []) : event.sqs.queueId => {
        function_id = function_id
        batch_size  = try(event.sqs.batchSize, null)
      } if try(event.sqs, null) != null
    }
  ]...)
  eventbridge_to_sqs = merge([
    for function_id, definition in local.handlers : {
      for event in try(definition.events, []) : event.sqs.queueId => {
        event_bus_name = try(event.sqs.eventbridge.eventBusName, var.resources.eventbridge[event.sqs.eventbridge.eventBusId].id, null)
        event_pattern  = try(jsonencode(event.sqs.eventbridge.eventPattern), null)
      } if try(event.sqs.eventbridge, null) != null
    }
  ]...)
  http_events = flatten([
    for function_id, definition in local.handlers : [
      for event in try(definition.events, []) : {
        function_name = definition.function_name
        http          = event.http
      } if try(event.http, null) != null
    ]
  ])
  api_definition = {
    for http_path in toset(flatten([for event in local.http_events : event.http.path])) : http_path => {
      for event in local.http_events : upper(event.http.method) => merge({
        function_name = event.function_name
      }, try(event.http.authorizer, null) != null ? { authorizer = event.http.authorizer } : {})
      if event.http.path == http_path
    }
  }
  scheduled_events = merge({
    for function_id, definition in local.handlers : "lambda-warmer-${definition.function_name}" => {
      function_name = definition.function_name
      function_id   = function_id
      schedule = {
        rate        = try(definition.warmer.rate, "rate(5 minutes)")
        description = try(definition.warmer.description, "Lambda warmer for ${definition.function_name}")
        input = try(
          definition.warmer.input,
          try(definition.warmer.inputPath, null) == null && try(definition.warmer.inputTransformer, null) == null
          ? "__WARMER__"
          : null
        )
        inputPath        = try(definition.warmer.inputPath, null)
        inputTransformer = try(definition.warmer.inputTransformer, null)
      }
    } if try(definition.warmer.enabled, true) != false
    }, [
    for function_id, definition in local.handlers : {
      for idx, event in try(definition.events, []) : try(event.ruleNamePrefix, "${function_id}-${idx}") => {
        function_name = definition.function_name
        function_id   = function_id
        schedule      = event.schedule
      } if try(event.schedule, null) != null
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
