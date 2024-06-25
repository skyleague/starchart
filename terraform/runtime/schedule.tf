resource "aws_cloudwatch_event_rule" "scheduled" {
  for_each = module.config_lambda.scheduled_events

  name        = try(each.value.schedule.ruleName, null)
  name_prefix = try(each.value.schedule.ruleName, null) == null ? substr(each.key, 0, 64 - 26) : null

  event_bus_name = "default"
  description    = try(each.value.schedule.description, "Scheduled event, rate ${each.value.schedule.rate}")

  schedule_expression = each.value.schedule.rate
  state               = try(each.value.schedule.enabled, true) ? "ENABLED" : "DISABLED"
}

resource "aws_cloudwatch_event_target" "scheduled" {
  for_each = module.config_lambda.scheduled_events

  rule      = aws_cloudwatch_event_rule.scheduled[each.key].id
  target_id = each.key

  input = try(
    jsonencode(each.value.schedule.input),
    try(each.value.schedule.inputPath, null) == null && try(each.value.schedule.inputTransformer, null) == null
    ? "{}"
    : null
  )
  input_path = try(each.value.schedule.inputPath, null)
  dynamic "input_transformer" {
    for_each = try(each.value.schedule.inputTransformer, null) != null ? [each.value.schedule.inputTransformer] : []

    content {
      input_paths    = try(input_transformer.value.inputPaths, null)
      input_template = input_transformer.value.inputTemplate
    }
  }

  arn = module.lambda[each.value.function_id].lambda.arn

  lifecycle {
    precondition {
      condition     = try(each.value.input, null) == null || try(each.value.inputPath, null) == null
      error_message = "Cannot specify both input and inputPath"
    }

    precondition {
      condition     = try(each.value.input, null) == null || try(each.value.inputTransformer, null) == null
      error_message = "Cannot specify both input and inputTransformer"
    }

    precondition {
      condition     = try(each.value.inputPath, null) == null || try(each.value.inputTransformer, null) == null
      error_message = "Cannot specify both inputPath and inputTransformer"
    }
  }
}

resource "aws_lambda_permission" "scheduled" {
  for_each = module.config_lambda.scheduled_events

  function_name = module.lambda[each.value.function_id].lambda.arn
  action        = "lambda:InvokeFunction"
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.scheduled[each.key].arn
}
