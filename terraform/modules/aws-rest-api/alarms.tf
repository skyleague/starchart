module "api_monitoring" {
  source = "../aws-cw-alarms-apigw"

  api_id   = aws_api_gateway_rest_api.this.id
  api_name = aws_api_gateway_rest_api.this.name
  route_alarms = merge([
    for stage in var.stages :
    { for endpoint in flatten([
      for path, path_config in try(var.definition, {}) : [
        for method, details in path_config : {
          key    = "${stage}-${method}-${path}"
          values = {
            path   = path
            method = method
            stage  = stage
            api_id = aws_api_gateway_rest_api.this.id
            name   = aws_api_gateway_rest_api.this.name
            metrics = details.monitoring
          }
        }
      ]
    ]) : endpoint.key => endpoint.values }
  ]...)
  monitoring = var.monitoring
  alarm_actions = try(var.monitoring.actions.alarm, [])
  ok_actions    = try(var.monitoring.actions.ok, [])
}