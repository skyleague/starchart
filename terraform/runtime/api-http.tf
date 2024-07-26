variable "http_api" {
  type        = any
  description = "The custom configuration for the API Gateway. Most of it will be inferred from Lambda events."
  default     = null
}

module "http_api_settings" {
  count  = var.http_api != null || try(local.starchart.stack.httpApi, null) != null ? 1 : 0
  source = "./http-api-settings"

  name = try(var.http_api.defer_deployment, local.starchart.stack.httpApi.deferDeployment, null) ? local.starchart.config.project_name : try(var.http_api.name, local.starchart.stack.httpApi.name, local.config.stack)

  definition                   = try(var.http_api.definition, local.starchart.stack.httpApi.definition, {})
  defer_deployment             = try(var.http_api.defer_deployment, local.starchart.stack.httpApi.deferDeployment, null)
  disable_execute_api_endpoint = try(var.http_api.disable_execute_api_endpoint, local.starchart.stack.httpApi.disableExecuteApiEndpoint, null)
  request_authorizers = {
    for name, authorizer in merge({
      for name, authorizer in try(var.http_api.authorizers, local.starchart.stack.httpApi.authorizers, {}) : name => {
        type            = authorizer.type
        identity_source = try(authorizer.identitySource, null)
        ttl_in_seconds  = try(authorizer.ttlInSeconds, null)
        function_id     = try(authorizer.functionId, null)
        security_scheme = try(authorizer.securityScheme, null)
      } if try(authorizer.type, "request") == "request"
      },
      module.config_lambda.request_authorizers
      ) : name => merge(authorizer, {
        lambda = {
          function_name = coalesce(
            try(authorizer.function_name, null),
            module.config_lambda.lambda_definitions[authorizer.function_id].function_name
          )
        }
    })
  }
  jwt_authorizers = {
    for name, authorizer in try(var.http_api.authorizers, local.starchart.stack.httpApi.authorizers, {}) : name => {
      type            = authorizer.type
      identity_source = try(authorizer.identitySource, null)
      ttl_in_seconds  = try(authorizer.ttlInSeconds, null)
      issuer          = try(authorizer.issuer, null)
      audience        = try(authorizer.audience, null)
      security_scheme = try(authorizer.securityScheme, null)
    } if try(authorizer.type, null) == "jwt"
  }
  default_authorizer = try(var.http_api.default_authorizer, local.starchart.stack.httpApi.defaultAuthorizer, null)
}

locals {
  _http_api_lambda_api_definition = {
    for http_path, path_items in module.config_lambda.api_definition : http_path => {
      for http_method, path_item in path_items : http_method => merge(path_item, {
        authorizer = try(coalesce(try(path_item.authorizer, null), module.http_api_settings[0].default_authorizer), null)
      })
    }
  }
  http_api_definition = merge(try(module.http_api_settings[0].definition, {}), {
    for http_path, path_items in local._http_api_lambda_api_definition : http_path => merge(try(module.http_api_settings[0].definition[http_path], {}), {
      for http_method, path_item in path_items : http_method => {
        lambda = {
          function_name = path_item.function_name
        }

        authorizer = try(path_item.authorizer, null) == null ? null : merge({
            name   = try(var.http_api.authorizers[path_item.authorizer.name].name, "${local.config.stack}-${path_item.authorizer.name}")
            scopes = try(path_item.authorizer.scopes, null)
          },
          # these should not be defined here
          lookup(module.http_api_settings[0].request_authorizers, path_item.authorizer.name, {}),
          lookup(module.http_api_settings[0].jwt_authorizers, path_item.authorizer.name, {}),
        )

        security = try(path_item.security, null)
      }
    })
  })
}

module "http_api" {
  count  = length(module.http_api_settings) > 0 && !try(module.http_api_settings[0].defer_deployment, false) ? 1 : 0
  source = "../modules/aws-http-api"

  name = module.http_api_settings[0].name

  region     = local.starchart.aws_region
  account_id = local.starchart.aws_account_id
  definition = local.http_api_definition

  disable_execute_api_endpoint = module.http_api_settings[0].disable_execute_api_endpoint
  depends_on                   = [module.lambda]
}

output "deferred_http_api_input" {
  sensitive = true
  value = try(module.http_api_settings[0].defer_deployment, false) ? jsonencode({
    name = module.http_api_settings[0].name

    region     = local.starchart.aws_region
    account_id = local.starchart.aws_account_id
    definition = local.http_api_definition

    disable_execute_api_endpoint = module.http_api_settings[0].disable_execute_api_endpoint
  }) : null
}

output "http_api" {
  value = try(module.http_api[0], null)
}
