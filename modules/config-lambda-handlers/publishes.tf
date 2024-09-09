locals {
  publishes = {
    for function_id, definition in local.handlers : function_id => {
      eventbridge = [for event in try(definition.publishes, []) : event.eventbridge if try(event.eventbridge, null) != null]
      sqs         = [for event in try(definition.publishes, []) : event.sqs if try(event.sqs, null) != null]
    }
  }
}

output "publishes" {
  value = local.publishes
}
