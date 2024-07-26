variable "rest_api" {
  type        = any
  description = "The custom configuration for the API Gateway. Most of it will be inferred from Lambda events."
  default     = null
}

module "rest_api_settings" {
  count  = var.rest_api != null || try(local.starchart.stack.restApi, null) != null ? 1 : 0
  source = "./rest-api-settings"

  name                         = try(var.rest_api.defer_deployment, local.starchart.stack.restApi.deferDeployment, null) ? local.starchart.config.project_name : try(var.rest_api.name, local.starchart.stack.restApi.name, local.config.stack)
  definition                   = try(var.rest_api.definition, local.starchart.stack.restApi.definition, {})
  defer_deployment             = try(var.rest_api.defer_deployment, local.starchart.stack.restApi.deferDeployment, null)
  disable_execute_api_endpoint = try(var.rest_api.disable_execute_api_endpoint, local.starchart.stack.restApi.disableExecuteApiEndpoint, null)
  authorizers = merge({
    for name, authorizer in try(var.rest_api.authorizers, local.starchart.stack.restApi.authorizers, {}) : name => {
      type = authorizer.type

      # request type
      function_id = try(authorizer.functionId, null)

      # jwt type
    }
    },
    module.config_lambda.request_authorizers
  )
  default_authorizer = try(var.rest_api.default_authorizer, local.starchart.stack.restApi.defaultAuthorizer, null)
}

locals {
  _rest_api_lambda_api_definition = {
    for http_path, path_items in module.config_lambda.api_definition : http_path => {
      for http_method, path_item in path_items : http_method => merge(path_item, {
        authorizer = try(coalesce(try(path_item.authorizer, null), module.rest_api_settings[0].default_authorizer), null)
      })
    }
  }
  rest_api_definition = merge(try(module.rest_api_settings[0].definition, {}), {
    for http_path, path_items in local._rest_api_lambda_api_definition : http_path => merge(try(module.rest_api_settings[0].definition[http_path], {}), {
      for http_method, path_item in path_items : http_method => {

        lambda = {
          function_name = path_item.function_name
        }

        authorizer = try(path_item.authorizer, null) == null ? null : {
          name = try(module.rest_api_settings[0].authorizers[path_item.authorizer].name, "${local.config.stack}-${path_item.authorizer}")
          lambda = {
            function_name = coalesce(
              try(module.rest_api_settings[0].authorizers[path_item.authorizer].function_name, null),
              module.config_lambda.lambda_definitions[module.rest_api_settings[0].authorizers[path_item.authorizer].function_id].function_name
            )
          }
          header             = try(module.rest_api_settings[0].authorizers[path_item.authorizer].header, null)
          authorizerType     = try(module.rest_api_settings[0].authorizers[path_item.authorizer].type, null)
          identitySource     = try(join(",", module.rest_api_settings[0].authorizers[path_item.authorizer].identity_source), null)
          resultTtlInSeconds = try(module.rest_api_settings[0].authorizers[path_item.authorizer].ttl_in_seconds, null)
        }
      }
    })
  })
}

module "rest_api" {
  count  = length(module.rest_api_settings) > 0 && !try(module.rest_api_settings[0].defer_deployment, false) ? 1 : 0
  source = "git::https://github.com/skyleague/aws-rest-api.git?ref=v3.1.0"

  name = module.rest_api_settings[0].name

  region     = local.starchart.aws_region
  account_id = local.starchart.aws_account_id
  definition = local.rest_api_definition

  disable_execute_api_endpoint = module.rest_api_settings[0].disable_execute_api_endpoint
  depends_on                   = [module.lambda]
}

output "deferred_rest_api_input" {
  sensitive = true
  value = try(module.rest_api_settings[0].defer_deployment, false) ? jsonencode({
    name = module.rest_api_settings[0].name

    region     = local.starchart.aws_region
    account_id = local.starchart.aws_account_id
    definition = local.rest_api_definition

    disable_execute_api_endpoint = module.rest_api_settings[0].disable_execute_api_endpoint
  }) : null
}

output "rest_api" {
  value = try(module.rest_api[0], null)
}
