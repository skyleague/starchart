resource "aws_lambda_permission" "api_invoke" {
  for_each = merge([
    for http_path, path_items in var.definition : {
      for http_method, path_item in path_items : "${upper(http_method)} ${http_path}" => {
        function_name = path_item.lambda.function_name
        http_path     = http_path
        http_method   = http_method
      } if try(path_item.lambda, null) != null
    }
  ]...)

  action        = "lambda:InvokeFunction"
  function_name = each.value.function_name
  principal     = "apigateway.amazonaws.com"

  # More: http://docs.aws.amazon.com/apigateway/latest/developerguide/api-gateway-control-access-using-iam-policies-to-invoke-api.html
  source_arn   = "arn:aws:execute-api:${local.region}:${local.account_id}:${aws_apigatewayv2_api.this.id}/*/${upper(each.value.http_method)}${each.value.http_path}"
  statement_id = "AllowExecutionFromAPIGateway${substr(sha256("${aws_apigatewayv2_api.this.id} ${each.key}"), 0, 8)}"
}

resource "aws_lambda_permission" "authorizer_invoke" {
  for_each = merge(flatten([
    for http_path, path_items in var.definition : flatten([
      for http_method, path_item in path_items : zipmap([path_item.authorizer.name], [{
        function_name = path_item.authorizer.lambda.function_name
      }]) if try(path_item.authorizer.lambda, null) != null
    ])
  ])...)

  action        = "lambda:InvokeFunction"
  function_name = each.value.function_name
  principal     = "apigateway.amazonaws.com"
  # More: http://docs.aws.amazon.com/apigateway/latest/developerguide/api-gateway-control-access-using-iam-policies-to-invoke-api.html
  source_arn   = "arn:aws:execute-api:${local.region}:${local.account_id}:${aws_apigatewayv2_api.this.id}/authorizers/*"
  statement_id = "AllowExecutionFromAPIGatewayAuthorizer${substr(sha256("${aws_apigatewayv2_api.this.id} ${each.key}"), 0, 8)}"
}
