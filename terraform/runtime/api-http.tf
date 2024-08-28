variable "http_api" {
  type = object({
    name = optional(string)

    definition       = optional(string, "{}")
    defer_deployment = optional(bool, false)

    disable_execute_api_endpoint = optional(bool, true)

    authorizers = optional(map(object({
      identity_source = optional(list(string), [
        "$context.httpMethod",
        "$context.path",
        "$request.header.Authorization",
      ])
      function_id    = optional(string)
      function_name  = optional(string)
      ttl_in_seconds = optional(number, 60)
      type           = optional(string, "request")

      enable_simple_responses = optional(bool, false)
      payload_format_version  = optional(string, "2.0")
    })), {})

    default_authorizer = optional(string)
  })
  description = "The custom configuration for the API Gateway. Most of it will be inferred from Lambda events."
  default     = null
}

locals {
  http_api_name = try(coalesce(var.http_api.name, local.config.stack), null)

  _http_api_definition_parsed = try(jsondecode(var.http_api.definition), {})

  _http_api_lambda_api_definition = {
    for http_path, path_items in module.config_lambda.api_definition : http_path => {
      for http_method, path_item in path_items : http_method => merge(path_item, {
        authorizer = try(coalesce(try(path_item.authorizer, null), var.http_api.default_authorizer), null)
      })
    }
  }

  http_api_definition = merge(local._http_api_definition_parsed, {
    for http_path, path_items in local._http_api_lambda_api_definition : http_path => merge(try(local._http_api_definition_parsed[http_path], {}), {
      for http_method, path_item in path_items : http_method => {

        lambda = {
          function_name = path_item.function_name
        }

        authorizer = try(path_item.authorizer, null) == null ? null : {
          name = try(var.rest_api.authorizers[path_item.authorizer].name, "${local.config.stack}-${path_item.authorizer}")
          lambda = {
            function_name = coalesce(
              try(var.http_api.authorizers[path_item.authorizer].function_name, null),
              module.config_lambda.lambda_definitions[var.http_api.authorizers[path_item.authorizer].function_id].function_name
            )
          }
          header             = try(var.http_api.authorizers[path_item.authorizer].header, null)
          authorizerType     = try(var.http_api.authorizers[path_item.authorizer].type, null)
          identitySource     = try(join(",", var.http_api.authorizers[path_item.authorizer].identity_source), null)
          resultTtlInSeconds = try(var.http_api.authorizers[path_item.authorizer].ttl_in_seconds, null)

          authorizerPayloadFormatVersion = try(var.http_api.authorizers[path_item.authorizer].payload_format_version, "2.0")
          enableSimpleResponses          = try(var.http_api.authorizers[path_item.authorizer].enable_simple_responses, false)
        }
      }
    })
  })
}

module "http_api" {
  count  = length(keys(local.http_api_definition)) > 0 && var.http_api != null && !try(var.http_api.defer_deployment, false) ? 1 : 0
  source = "../modules/aws-http-api"

  name = local.http_api_name

  region     = var.starchart.aws_region
  account_id = var.starchart.aws_account_id
  definition = local.http_api_definition

  disable_execute_api_endpoint = var.http_api.disable_execute_api_endpoint
  depends_on                   = [module.lambda]
}

output "deferred_http_api_input" {
  sensitive = true
  value = try(var.http_api.defer_deployment, false) ? jsonencode({
    name = local.http_api_name

    region     = var.starchart.aws_region
    account_id = var.starchart.aws_account_id
    definition = local.http_api_definition

    disable_execute_api_endpoint = var.http_api.disable_execute_api_endpoint
  }) : null
}

output "http_api" {
  value = try(module.http_api[0], null)
}
