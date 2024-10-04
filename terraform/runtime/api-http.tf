variable "http_api" {
  type        = any
  description = "The custom configuration for the API Gateway. Most of it will be inferred from Lambda events."
  default     = null
}

module "http_api_settings" {
  count  = var.http_api != null || try(local.config.stack.http_api, null) != null ? 1 : 0
  source = "./http-api-settings"

  name = try(var.http_api.defer_deployment, local.config.stack.http_api.defer_deployment, null) ? local.starchart.config.project_name : try(var.http_api.name, local.config.stack.http_api.name, local.config.stack_name)

  definition                   = try(var.http_api.definition, local.config.stack.http_api.definition, {})
  defer_deployment             = try(var.http_api.defer_deployment, local.config.stack.http_api.defer_deployment, null)
  disable_execute_api_endpoint = try(var.http_api.disable_execute_api_endpoint, local.config.stack.http_api.disable_execute_api_endpoint, null)
  request_authorizers = {
    for name, authorizer in merge({
      for name, authorizer in try(var.http_api.authorizers, coalesce(local.config.stack.http_api.authorizers, {})) : name => {
        type            = authorizer.type
        identity_source = authorizer.identity_source

        ttl_in_seconds  = authorizer.ttl_in_seconds
        function_id     = authorizer.function_id
        function_name     = authorizer.function_name

        security_scheme = authorizer.security_Scheme
      } if coalesce(authorizer.type, "request") == "request"
      },
      module.config_lambda.request_authorizers
      ) : name => merge(authorizer, {
        function_name = coalesce(
          try(authorizer.function_name, null),
          module.config_lambda.lambda_definitions[authorizer.function_id].function_name
        )
    })
  }
  jwt_authorizers = {
    for name, authorizer in try(var.http_api.authorizers, coalesce(local.config.stack.http_api.authorizers, {})) : name => {
      type            = authorizer.type
      identity_source = authorizer.identity_source
      ttl_in_seconds  = authorizer.ttl_in_seconds

      issuer          = authorizer.issuer
      audience        = authorizer.audience
      
      security_scheme = authorizer.security_scheme
    } if authorizer.type == "jwt"
  }
  default_authorizer = try(var.http_api.default_authorizer, local.config.stack.http_api.default_authorizer, null)
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

        authorizer = try(path_item.authorizer, null) == null ? null : {
          name   = try(var.http_api.authorizers[path_item.authorizer.name].name, path_item.authorizer.name)
          scopes = try(path_item.authorizer.scopes, null)
        }

        monitoring = {
          for type, values in {
            for type in distinct(concat(
              keys(try(local.config.monitoring.http_api.route, {})),
              keys(try(local.config.stack.http_api.monitoring.route, {})),
              keys(try(path_item.monitoring, {}))
            )) : type => {
              for subtype in ["static", "anomaly"] : subtype => {
                for statistic, values in {
                  for statistic in distinct(concat(
                    keys(try(local.config.monitoring.http_api.route[type][subtype], {})),
                    keys(try(local.config.stack.http_api.monitoring.route[type][subtype], {})),
                    keys(try(path_item.monitoring[type][subtype], {}))
                  )) :
                  statistic => merge(
                    try({ for k, v in local.config.monitoring.http_api.route[type][subtype][statistic] : k => v if v != null }, {}),
                    try({ for k, v in local.config.stack.http_api.monitoring.route[type][subtype][statistic] : k => v if v != null }, {}),
                    try({ for k, v in path_item.monitoring[type][subtype][statistic] : k => v if v != null }, {})
                  )
                } : statistic => values if length(values) > 0
              }
            }
          }: type => values if length(values) > 0
        }
        security = try(path_item.security, null)
      }
    })
  })
  http_api_monitoring = merge({
    for type, type_values in {
      for type in distinct(concat(
        keys(try(local.config.monitoring.http_api.api, {})),
        keys(try(local.config.stack.http_api.monitoring.api, {}))
      )) : type => {
        for subtype in ["static", "anomaly"] : subtype => {
          for statistic, values in {
            for statistic in distinct(concat(
              keys(try(local.config.monitoring.http_api.api[type][subtype], {})),
              keys(try(local.config.stack.http_api.monitoring.api[type][subtype], {}))
            )) :
            statistic => merge(
              try({ for k, v in local.config.monitoring.http_api.api[type][subtype][statistic] : k => v if v != null }, {}),
              try({ for k, v in local.config.stack.http_api.monitoring.api[type][subtype][statistic] : k => v if v != null }, {}),
            )
          } : statistic => values if length(values) > 0
        }
      }
    } : type => {
      for subtype, subtype_values in type_values : subtype => subtype_values if length(subtype_values) > 0
    } if type != "actions" && length(type_values) > 0
  }, {
    actions = try(local.config.monitoring.actions, { ok = [], alarm = [] })
  })
}

module "http_api" {
  count  = length(module.http_api_settings) > 0 && !try(module.http_api_settings[0].defer_deployment, false) ? 1 : 0
  source = "../modules/aws-http-api"

  name = module.http_api_settings[0].name

  region     = local.starchart.aws_region
  account_id = local.starchart.aws_account_id
  definition = local.http_api_definition
  monitoring = local.http_api_monitoring

  request_authorizers = module.http_api_settings[0].request_authorizers
  jwt_authorizers     = module.http_api_settings[0].jwt_authorizers

  disable_execute_api_endpoint = module.http_api_settings[0].disable_execute_api_endpoint
  depends_on                   = [module.lambda]
}

locals {
  _cloudwatch_http_api = merge({
    for stage, logs in try(module.http_api[0].access_log_groups, {}) : "access-${stage}" => {
      name = logs.name
      arn  = logs.arn
    }
    }, {
    for stage, logs in try(module.http_api[0].execution_log_groups, {}) : "execution-${stage}" => {
      name = logs.name
      arn  = logs.arn
    }
  })
}

output "deferred_http_api_input" {
  value = try(module.http_api_settings[0].defer_deployment, false) ? jsonencode({
    name = module.http_api_settings[0].name

    region     = local.starchart.aws_region
    account_id = local.starchart.aws_account_id
    definition = local.http_api_definition
    monitoring = local.http_api_monitoring

    request_authorizers = module.http_api_settings[0].request_authorizers
    jwt_authorizers     = module.http_api_settings[0].jwt_authorizers

    disable_execute_api_endpoint = module.http_api_settings[0].disable_execute_api_endpoint
  }) : null
}

output "http_api" {
  value = try(module.http_api[0], null)
}
