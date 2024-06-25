variable "http_api" {
  type = object({
    name = optional(string)

    definition = optional(string, "{}")

    disable_execute_api_endpoint = optional(bool, true)

    authorizers = optional(map(object({
      identity_source = optional(list(string), [
        "context.httpMethod",
        "context.path",
        "method.request.header.Authorization",
      ])
      function_id             = optional(string)
      ttl_in_seconds          = optional(number, 60)
      type                    = optional(string, "request")
      enable_simple_responses = optional(bool)
    })), {})

  })
  description = "The custom configuration for the API Gateway. Most of it will be inferred from Lambda events."
  default     = null
}

locals {
  http_api_name = try(coalesce(var.http_api.name, local.config.project_name), null)

  _http_api_definition_parsed = try(jsondecode(var.http_api.definition), {})
  http_api_definition = merge(local._http_api_definition_parsed, {
    for http_path, path_items in module.config_lambda.api_definition : http_path => merge(try(local._http_api_definition_parsed[http_path], {}), {
      for http_method, path_item in path_items : http_method => {

        lambda = {
          function_name = path_item.function_name
        }

        authorizer = try(path_item.authorizer, null) == null ? null : {
          name = try(var.http_api.authorizers[path_item.authorizer].name, path_item.authorizer)
          lambda = {
            function_name = module.config_lambda.functions[var.http_api.authorizers[path_item.authorizer].function_id].function_name
          }
          header             = try(var.http_api.authorizers[path_item.authorizer].header, null)
          authorizerType     = try(var.http_api.authorizers[path_item.authorizer].type, null)
          identitySource     = try(join(",", var.http_api.authorizers[path_item.authorizer].identity_source), null)
          resultTtlInSeconds = try(var.http_api.authorizers[path_item.authorizer].ttl_in_seconds, null)
        }

      }
    })
  })
}

module "http_api" {
  source = "../../modules/aws-http-api"
  count  = length(keys(local.http_api_definition)) > 0 && var.http_api != null ? 1 : 0

  name = local.http_api_name

  region     = data.aws_region.current.name
  account_id = data.aws_caller_identity.current.account_id
  definition = local.http_api_definition

  disable_execute_api_endpoint = var.http_api.disable_execute_api_endpoint
  depends_on                   = [module.lambda]
}

# output "http_api" {
#   value = try(module.http_api[0], null)
# }
