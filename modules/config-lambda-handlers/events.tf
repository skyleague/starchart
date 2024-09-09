locals {
  sqs_triggers = merge([
    for function_id, definition in local.handlers : {
      for event in try(definition.events, []) : event.sqs.queueId => true if try(event.sqs, null) != null
    }
  ]...)
  eventbridge_to_sqs = merge([
    for function_id, definition in local.handlers : {
      for event in try(definition.events, []) : event.sqs.queueId => true if try(event.sqs.eventbridge, null) != null
    }
  ]...)
  http_events = flatten([
    for function_id, definition in local.handlers : [
      for event in try(definition.events, []) : true if try(event.http, null) != null
    ]
  ])
  scheduled_events = merge({
    for function_id, definition in local.handlers : "lambda-warmer-${definition.function_name}" => true if try(definition.warmer.enabled, true) != false
    }, [
    for function_id, definition in local.handlers : {
      for idx, event in try(definition.events, []) : try(event.ruleNamePrefix, "${function_id}-${idx}") => true if try(event.schedule, null) != null
    }
  ]...)
}

output "sqs_triggers" {
  value = local.sqs_triggers
}

output "eventbridge_to_sqs" {
  value = local.eventbridge_to_sqs
}

output "scheduled_events" {
  value = local.scheduled_events
}
