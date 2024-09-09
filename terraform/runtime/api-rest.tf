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

  request_authorizers = {
    for name, authorizer in merge({
      for name, authorizer in try(var.http_api.authorizers, local.starchart.stack.httpApi.authorizers, {}) : name => {
        type            = authorizer.type
        identity_source = try(authorizer.identitySource, null)

        ttl_in_seconds  = try(authorizer.ttlInSeconds, null)
        function_id     = try(authorizer.functionId, null)
        function_name     = try(authorizer.functionName, null)

        security_scheme = try(authorizer.securityScheme, null)
      } if try(authorizer.type, "request") == "request"
      },
      module.config_lambda.request_authorizers
      ) : name => merge(authorizer, {
        function_name = coalesce(
          try(authorizer.function_name, null),
          module.config_lambda.lambda_definitions[authorizer.function_id].function_name
        )
    })
  }
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
          name   = try(var.rest_api.authorizers[path_item.authorizer.name].name, path_item.authorizer.name)
          scopes = try(path_item.authorizer.scopes, null)
        }
        
        security = try(path_item.security, null)
      }
    })
  })
}

module "rest_api" {
  count  = length(module.rest_api_settings) > 0 && !try(module.rest_api_settings[0].defer_deployment, false) ? 1 : 0
  source = "../modules/aws-rest-api"

  name = module.rest_api_settings[0].name

  region     = local.starchart.aws_region
  account_id = local.starchart.aws_account_id
  definition = local.rest_api_definition

  request_authorizers = module.rest_api_settings[0].request_authorizers

  disable_execute_api_endpoint = module.rest_api_settings[0].disable_execute_api_endpoint
  depends_on                   = [module.lambda]
}

output "deferred_rest_api_input" {
  value = try(module.rest_api_settings[0].defer_deployment, false) ? jsonencode({
    name = module.rest_api_settings[0].name

    region     = local.starchart.aws_region
    account_id = local.starchart.aws_account_id
    definition = local.rest_api_definition
    
    request_authorizers = module.rest_api_settings[0].request_authorizers

    disable_execute_api_endpoint = module.rest_api_settings[0].disable_execute_api_endpoint
  }) : null
}

output "rest_api" {
  value = try(module.rest_api[0], null)
}
