locals {
  invoke_arns = {
    for function_name in toset(flatten([
      for http_path, path_items in var.definition : flatten([
        for http_method, path_item in path_items : try([path_item.lambda.function_name], [])
      ])
    ])) : function_name => "arn:aws:apigateway:${local.region}:lambda:path/2015-03-31/functions/arn:aws:lambda:${local.region}:${local.account_id}:function:${function_name}/invocations"
  }

  authorizers = merge(
    {
      for name, authorizer in var.request_authorizers : name => merge({
        type = "apiKey"
        in   = "header"
        name = coalesce(try(authorizer.authorizer.header, null), "Authorization")
      },
      authorizer.security_scheme,
      {
        "x-amazon-apigateway-authtype" : "custom"
        "x-amazon-apigateway-authorizer" = merge(
          {
            type                           = "request"
            identitySource                 = authorizer.identity_source
            authorizerUri                  = "arn:aws:apigateway:${local.region}:lambda:path/2015-03-31/functions/arn:aws:lambda:${local.region}:${local.account_id}:function:${authorizer.function_name}/invocations"
            authorizerResultTtlInSeconds   = authorizer.ttl_in_seconds
          }
        )
      },
      authorizer.x-amazon-apigateway-authorizer
      )
    }
  )
  parsed_extensions = jsondecode(var.extensions)
  components = merge(try(local.parsed_extensions.components, {}), {
    securitySchemes = merge(
      try(local.parsed_extensions.components.securitySchemes, {}),
      local.authorizers
    )
  })
  parameters = {
    for http_path, path_items in var.definition : http_path => {
      for http_method, path_item in path_items : http_method => concat(
        coalesce(try(jsondecode(path_item.parameters), null), []),
        [
          for parameter in regexall("\\{([a-zA-Z0-9:._$-]+\\+?)\\}", http_path) : {
            in       = "path"
            required = true
            schema   = { type = "string" }
            name     = parameter[0]
          } if length([for param in coalesce(try(jsondecode(path_item.parameters), null), []) : param if param.name == parameter[0]]) == 0
        ]
      )
    }
  }
  compiled_definition = merge(local.parsed_extensions, {
    openapi = try(local.parsed_extensions.openapi, "3.0.1")
    paths = {
      for http_path, path_items in var.definition : http_path => {
        for http_method, path_item in path_items : http_method == "any" ? "x-amazon-apigateway-any-method" : lower(http_method) => { for k, v in {
          "x-amazon-apigateway-integration" = merge(try(jsondecode(path_item["x-amazon-apigateway-integration"]), {}), try(path_item.lambda, null) != null ? {
            httpMethod = "POST"
            type       = "aws_proxy"
            uri        = local.invoke_arns[path_item.lambda.function_name]
          } : {})
          parameters = length(try(local.parameters[http_path][http_method], [])) > 0 ? local.parameters[http_path][http_method] : null
          responses  = try(jsondecode(path_item.responses), null)
          security   = try(path_item.authorizer, null) != null ? [{
            "${path_item.authorizer.name}" = path_item.authorizer.scopes
          }] : null
        } : k => v if v != null }
      }
    }
    components = local.components
  })
}

