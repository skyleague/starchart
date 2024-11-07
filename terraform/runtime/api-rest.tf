variable "rest_api" {
  type        = any
  description = "The custom configuration for the API Gateway. Most of it will be inferred from Lambda events."
  default     = null
}

module "rest_api_settings" {
  count  = var.rest_api != null || try(local.config.stack.rest_api, null) != null ? 1 : 0
  source = "./rest-api-settings"

  name                         = try(var.rest_api.defer_deployment, local.config.stack.rest_api.defer_deployment, null) ? local.starchart.config.project_name : try(var.rest_api.name, local.config.stack.rest_api.name, local.config.stack_name)
  
  definition                   = try(var.rest_api.definition, local.config.stack.rest_api.definition, {})
  defer_deployment             = try(var.rest_api.defer_deployment, local.config.stack.rest_api.defer_deployment, null)
  disable_execute_api_endpoint = try(var.rest_api.disable_execute_api_endpoint, local.config.stack.rest_api.disable_execute_api_endpoint, null)
  request_authorizers = {
    for name, authorizer in merge({
      for name, authorizer in try(var.rest_api.authorizers, coalesce(local.config.stack.rest_api.authorizers, {})) : name => {
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
  default_authorizer = try(var.rest_api.default_authorizer, local.starchart.stack.restApi.default_authorizer, null)
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

        monitoring = {
          for type, values in {
            for type in distinct(concat(
              keys(try(local.config.monitoring.rest_api.route, {})),
              keys(try(local.config.stack.rest_api.monitoring.route, {})),
              keys(try(path_item.monitoring, {}))
            )) : type => {
              for subtype in ["static", "anomaly"] : subtype => {
                for statistic, values in {
                  for statistic in distinct(concat(
                    keys(try(local.config.monitoring.rest_api.route[type][subtype], {})),
                    keys(try(local.config.stack.rest_api.monitoring.route[type][subtype], {})),
                    keys(try(path_item.monitoring[type][subtype], {}))
                  )) :
                  statistic => merge(
                    try({ for k, v in local.config.monitoring.rest_api.route[type][subtype][statistic] : k => v if v != null }, {}),
                    try({ for k, v in local.config.stack.rest_api.monitoring.route[type][subtype][statistic] : k => v if v != null }, {}),
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
  rest_api_monitoring = merge({
    for type, type_values in {
      for type in distinct(concat(
        keys(try(local.config.monitoring.rest_api.api, {})),
        keys(try(local.config.stack.rest_api.monitoring.api, {}))
      )) : type => {
        for subtype in ["static", "anomaly"] : subtype => {
          for statistic, values in {
            for statistic in distinct(concat(
              keys(try(local.config.monitoring.rest_api.api[type][subtype], {})),
              keys(try(local.config.stack.rest_api.monitoring.api[type][subtype], {}))
            )) :
            statistic => merge(
              try({ for k, v in local.config.monitoring.rest_api.api[type][subtype][statistic] : k => v if v != null }, {}),
              try({ for k, v in local.config.stack.rest_api.monitoring.api[type][subtype][statistic] : k => v if v != null }, {}),
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

module "rest_api" {
  count  = length(module.rest_api_settings) > 0 && !try(module.rest_api_settings[0].defer_deployment, false) ? 1 : 0
  source = "../modules/aws-rest-api"

  name = module.rest_api_settings[0].name

  region     = local.starchart.aws_region
  account_id = local.starchart.aws_account_id
  definition = local.rest_api_definition
  monitoring = local.rest_api_monitoring

  request_authorizers = module.rest_api_settings[0].request_authorizers

  disable_execute_api_endpoint = module.rest_api_settings[0].disable_execute_api_endpoint
  depends_on                   = [module.lambda]
}


locals {
  _cloudwatch_rest_api = merge({
    for stage, logs in try(module.rest_api[0].access_log_groups, {}) : "access-${stage}" => {
      name = logs.name
      arn  = logs.arn
    }
    }, {
    for stage, logs in try(module.rest_api[0].execution_log_groups, {}) : "execution-${stage}" => {
      name = logs.name
      arn  = logs.arn
    }
  })
}

output "deferred_rest_api_input" {
  value = try(module.rest_api_settings[0].defer_deployment, false) ? jsonencode({
    name = module.rest_api_settings[0].name

    region     = local.starchart.aws_region
    account_id = local.starchart.aws_account_id
    definition = local.rest_api_definition
    monitoring = local.rest_api_monitoring
    
    request_authorizers = module.rest_api_settings[0].request_authorizers

    disable_execute_api_endpoint = module.rest_api_settings[0].disable_execute_api_endpoint
  }) : null
}

output "rest_api" {
  value = try(module.rest_api[0], null)
}
