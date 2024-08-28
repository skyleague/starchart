output "http_api" {
  value = aws_apigatewayv2_api.this
}

output "stage" {
  value = aws_apigatewayv2_api.this
}

output "access_log_groups" {
  value = aws_cloudwatch_log_group.access
}

output "execution_log_groups" {
  value = aws_cloudwatch_log_group.execution
}
