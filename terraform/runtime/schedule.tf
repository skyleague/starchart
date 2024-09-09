resource "aws_cloudwatch_event_rule" "scheduled" {
  for_each = module.config_lambda_handlers.scheduled_events

  name        = try(module.config_lambda.scheduled_events[each.key].schedule.ruleName, null)
  name_prefix = try(module.config_lambda.scheduled_events[each.key].schedule.ruleName, null) == null ? substr(each.key, 0, 64 - 26) : null

  event_bus_name = "default"
  description    = try(module.config_lambda.scheduled_events[each.key].schedule.description, "Scheduled event, rate ${module.config_lambda.scheduled_events[each.key].schedule.rate}")

  schedule_expression = module.config_lambda.scheduled_events[each.key].schedule.rate
  state               = try(module.config_lambda.scheduled_events[each.key].schedule.enabled, true) ? "ENABLED" : "DISABLED"
}

resource "aws_cloudwatch_event_target" "scheduled" {
  for_each = module.config_lambda_handlers.scheduled_events

  rule      = aws_cloudwatch_event_rule.scheduled[each.key].id
  target_id = each.key

  input = try(
    jsonencode(module.config_lambda.scheduled_events[each.key].schedule.input),
    try(module.config_lambda.scheduled_events[each.key].schedule.inputPath, null) == null && try(module.config_lambda.scheduled_events[each.key].schedule.inputTransformer, null) == null
    ? "{}"
    : null
  )
  input_path = try(module.config_lambda.scheduled_events[each.key].schedule.inputPath, null)
  dynamic "input_transformer" {
    for_each = try(module.config_lambda.scheduled_events[each.key].schedule.inputTransformer, null) != null ? [module.config_lambda.scheduled_events[each.key].schedule.inputTransformer] : []

    content {
      input_paths    = try(input_transformer.value.inputPaths, null)
      input_template = input_transformer.value.inputTemplate
    }
  }

  arn = module.lambda[module.config_lambda.scheduled_events[each.key].function_id].lambda.arn

  lifecycle {
    precondition {
      condition     = try(module.config_lambda.scheduled_events[each.key].input, null) == null || try(module.config_lambda.scheduled_events[each.key].inputPath, null) == null
      error_message = "Cannot specify both input and inputPath"
    }

    precondition {
      condition     = try(module.config_lambda.scheduled_events[each.key].input, null) == null || try(module.config_lambda.scheduled_events[each.key].inputTransformer, null) == null
      error_message = "Cannot specify both input and inputTransformer"
    }

    precondition {
      condition     = try(module.config_lambda.scheduled_events[each.key].inputPath, null) == null || try(module.config_lambda.scheduled_events[each.key].inputTransformer, null) == null
      error_message = "Cannot specify both inputPath and inputTransformer"
    }
  }
}

resource "aws_lambda_permission" "scheduled" {
  for_each = module.config_lambda_handlers.scheduled_events

  function_name = module.lambda[module.config_lambda.scheduled_events[each.key].function_id].lambda.arn
  action        = "lambda:InvokeFunction"
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.scheduled[each.key].arn
}
