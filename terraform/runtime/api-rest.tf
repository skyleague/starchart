variable "rest_api" {
  type = object({
    name = optional(string)

    definition       = optional(string, "{}")
    defer_deployment = optional(bool, false)

    disable_execute_api_endpoint = optional(bool, true)

    authorizers = optional(map(object({
      identity_source = optional(list(string), [
        "context.httpMethod",
        "context.path",
        "method.request.header.Authorization",
      ])
      function_id    = optional(string)
      function_name  = optional(string)
      ttl_in_seconds = optional(number, 60)
      type           = optional(string, "request")
    })), {})

    default_authorizer = optional(string)
  })
  description = "The custom configuration for the API Gateway. Most of it will be inferred from Lambda events."
  default     = null
}

locals {
  rest_api_name = try(coalesce(var.rest_api.name, local.config.stack), null)

  _rest_api_definition_parsed = try(jsondecode(var.rest_api.definition), {})

  _rest_api_lambda_api_definition = {
    for http_path, path_items in module.config_lambda.api_definition : http_path => {
      for http_method, path_item in path_items : http_method => merge(path_item, {
        authorizer = try(coalesce(try(path_item.authorizer, null), var.rest_api.default_authorizer), null)
      })
    }
  }

  rest_api_definition = merge(local._rest_api_definition_parsed, {
    for http_path, path_items in local._rest_api_lambda_api_definition : http_path => merge(try(local._rest_api_definition_parsed[http_path], {}), {
      for http_method, path_item in path_items : http_method => {

        lambda = {
          function_name = path_item.function_name
        }

        authorizer = try(path_item.authorizer, null) == null ? null : {
          name = try(var.rest_api.authorizers[path_item.authorizer].name, "${local.config.stack}-${path_item.authorizer}")
          lambda = {
            function_name = coalesce(
              try(var.rest_api.authorizers[path_item.authorizer].function_name, null),
              module.config_lambda.lambda_definitions[var.rest_api.authorizers[path_item.authorizer].function_id].function_name
            )
          }
          header             = try(var.rest_api.authorizers[path_item.authorizer].header, null)
          authorizerType     = try(var.rest_api.authorizers[path_item.authorizer].type, null)
          identitySource     = try(join(",", var.rest_api.authorizers[path_item.authorizer].identity_source), null)
          resultTtlInSeconds = try(var.rest_api.authorizers[path_item.authorizer].ttl_in_seconds, null)
        }
      }
    })
  })
}

module "rest_api" {
  count  = length(keys(local.rest_api_definition)) > 0 && var.rest_api != null && !try(var.rest_api.defer_deployment, false) ? 1 : 0
  source = "git@github.com:skyleague/aws-rest-api.git?ref=v3.1.0"

  name = local.rest_api_name

  region     = var.starchart.aws_region
  account_id = var.starchart.aws_account_id
  definition = local.rest_api_definition

  disable_execute_api_endpoint = var.rest_api.disable_execute_api_endpoint
  depends_on                   = [module.lambda]
}

output "deferred_rest_api_input" {
  sensitive = true
  value = try(var.rest_api.defer_deployment, false) ? jsonencode({
    name = local.rest_api_name

    region     = var.starchart.aws_region
    account_id = var.starchart.aws_account_id
    definition = local.rest_api_definition

    disable_execute_api_endpoint = var.rest_api.disable_execute_api_endpoint
  }) : null
}

# output "rest_api" {
#   value = try(module.rest_api[0], null)
# }
