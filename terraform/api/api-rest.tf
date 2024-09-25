
locals {
  _rest_api_stacks = {
    for stack, subs in local.starchart.stacks : stack => jsondecode(subs.runtime.deferred_rest_api_input) if try(subs.runtime.deferred_rest_api_input, null) != null
  }

  _rest_api_grouped_apis = {
    for name in distinct([for stack, input in local._rest_api_stacks : input.name]) : name => [
      for stack, input in local._rest_api_stacks : merge({stack = stack}, input) if input.name == name
    ]
  }

  rest_api_inputs = {
    for name, apis in local._rest_api_grouped_apis : name => {
      account_id                   = apis[0].account_id
      region                       = apis[0].region
      disable_execute_api_endpoint = anytrue([for api in apis : api.disable_execute_api_endpoint])
      request_authorizers = merge([
        for api in apis : {
          for auth_name, authorizer in api.request_authorizers : "${api.stack}-${auth_name}" => authorizer
        }
      ]...)
      monitoring = merge({
        for metric_type in distinct(flatten([for api in apis : keys(try(api.monitoring, {}))])) : metric_type => {
          anomaly = merge([
            for api in apis : try(api.monitoring[metric_type].anomaly, {})
          ]...)
          static = merge([
            for api in apis : try(api.monitoring[metric_type].static, {})
          ]...)
        }  if metric_type != "actions"
      }, {
        actions = merge([
          for api in apis : try(api.monitoring.actions, {})
        ]...)
      })
      definition = merge([
        for api in apis : {
          for path, methods in api.definition : path => {
            for method, config in methods : method => merge(
              config,
              {
                authorizer = try(config.authorizer, null) != null ? merge(config.authorizer, {
                  name = "${api.stack}-${config.authorizer.name}"
                }) : null
                security = try({
                  for authorizer_name, scopes in config.security : "${api.stack}-${authorizer_name}" => scopes
                }, null)
                monitoring = try(config.monitoring, null)
              }
            )
          }
        }
      ]...)
    }
  }
}


module "rest_api" {
  source = "../modules/aws-rest-api"

  for_each = local.rest_api_inputs

  name = each.key

  region     = each.value.region
  account_id = each.value.account_id
  definition = each.value.definition
  monitoring = each.value.monitoring
  
  request_authorizers = each.value.request_authorizers

  disable_execute_api_endpoint = each.value.disable_execute_api_endpoint
}
