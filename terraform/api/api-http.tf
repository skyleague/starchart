locals {
  _http_api_stacks = {
    for stack, subs in local.starchart.stacks : stack => jsondecode(subs.runtime.deferred_http_api_input) if try(subs.runtime.deferred_http_api_input, null) != null
  }

  http_api_inputs = {
    for name in toset([for stack, input in local._http_api_stacks : input.name]) : name => {
      account_id                   = toset([for stack, input in local._http_api_stacks : input.account_id if input.name == name])
      region                       = toset([for stack, input in local._http_api_stacks : input.region if input.name == name])
      disable_execute_api_endpoint = anytrue([for stack, input in local._http_api_stacks : input.disable_execute_api_endpoint if input.name == name])
      request_authorizers = merge([
        for stack, input in local._http_api_stacks : {
          for name, authorizer in input.request_authorizers : "${stack}-${name}" => authorizer
        } if input.name == name
      ]...)
      jwt_authorizers = merge([
        for stack, input in local._http_api_stacks : {
          for name, authorizer in input.jwt_authorizers : "${stack}-${name}" => authorizer
        } if input.name == name
      ]...)
      definition = {
        for path in toset(flatten([for stack, input in local._http_api_stacks : keys(input.definition)])) : path => {
          for method in toset(flatten([for stack, input in local._http_api_stacks : try(keys(input.definition[path]), [])])) : method => [for stack, input in local._http_api_stacks : merge(
            input.definition[path][method],
            {
              authorizer = try(input.definition[path][method].authorizer, null) != null ? merge(input.definition[path][method].authorizer, {
                name = "${stack}-${input.definition[path][method].authorizer.name}"
              }) : null
              security = try({
                for authorizer_name, scopes in input.definition[path][method].security : "${name}-${authorizer_name}" => scopes
              }, null)
            }
          ) if try(input.definition[path][method], null) != null][0]
        }
      }
    }
  }
}


module "http_api" {
  source = "../modules/aws-http-api"

  for_each = local.http_api_inputs

  name = each.key

  region     = tolist(each.value.region)[0]
  account_id = tolist(each.value.account_id)[0]
  definition = each.value.definition

  request_authorizers = each.value.request_authorizers
  jwt_authorizers = each.value.jwt_authorizers

  disable_execute_api_endpoint = each.value.disable_execute_api_endpoint
}
