resource "aws_apigatewayv2_api" "this" {
  name        = var.name
  description = coalesce(var.description, "API for ${var.name}")

  protocol_type = "HTTP"

  disable_execute_api_endpoint = var.disable_execute_api_endpoint

  body = jsonencode(local.compiled_definition)
}

resource "aws_apigatewayv2_stage" "this" {
  for_each = var.stages
  api_id   = aws_apigatewayv2_api.this.id
  name     = each.value

  auto_deploy = true

  dynamic "access_log_settings" {
    for_each = var.custom_access_logs_format != null ? [var.custom_access_logs_format] : []
    content {
      destination_arn = aws_cloudwatch_log_group.access[each.key].arn
      format          = jsonencode(access_log_settings.value)
    }
  }

  default_route_settings {
    # only supported for websockets
    # logging_level            = var.logging_level
    # data_trace_enabled       = var.data_trace_enabled
    detailed_metrics_enabled = var.metrics_enabled

    throttling_burst_limit = var.throttling_burst_limit
    throttling_rate_limit  = var.throttling_rate_limit
  }

  depends_on = [
    aws_cloudwatch_log_group.execution,
    aws_lambda_permission.api_invoke,
    aws_lambda_permission.authorizer_invoke,
  ]
}
