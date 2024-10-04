locals {
  camel_to_snake = {
    httpApi = "http_api"
    restApi = "rest_api"
    successRate = "success_rate"
  }
}

output "project_name" {
  value = var.project_name
}

output "project_identifier" {
  value = var.project_identifier
}

output "environment" {
  value = var.environment
}

output "stack_name" {
  value = var.stack_name
}

output "repo_root" {
  value = var.repo_root
}

output "monitoring" {
  value = merge({
    actions = {
      alarm = try(var.bootstrap.chatbot, null) != null ? [var.bootstrap.chatbot.sns_notication_arn] : []
      ok = try(var.bootstrap.chatbot, null) != null ? [var.bootstrap.chatbot.sns_notication_arn] : []
    }
  }, var.starchart.monitoring != null ? {
    for api_type, api_config in var.starchart.monitoring : lookup(local.camel_to_snake, api_type, api_type) => {
      for route_or_api, route_or_api_details in coalesce(api_config, {}) : lookup(local.camel_to_snake, route_or_api, route_or_api) => {
        for metric_type, metric_config in coalesce(route_or_api_details, {}) : lookup(local.camel_to_snake, metric_type, metric_type) => { 
          static = {
            for key, value in try(metric_config.static, {}) : lookup(local.camel_to_snake, key, key) => {
              enabled            = try(value.enabled, null)
              threshold          = try(value.threshold, null)
              period             = try(value.period, null)
              evaluation_periods = try(value.evaluationPeriods, null)
            }
          }
          anomaly = {
            for key, value in try(metric_config.anomaly, {}) : lookup(local.camel_to_snake, key, key) => {
              enabled = try(value.enabled, false)
              evaluation_periods              = try(value.evaluationPeriods, null)
              datapoints_to_alarm             = try(value.datapointsToAlarm, null)
              band_width_standard_deviations  = try(value.bandWidthStandardDeviations, null)
              metric_period                   = try(value.metricPeriod, null)
            }
          }
        }
      }
    } if api_type != "actions"
  } : {})
}

output "stack" {
  value = var.stack != null ? {
    path = var.stack.path
    http_api = var.stack.httpApi != null ? {
      name = var.stack.httpApi.name
      defer_deployment = var.stack.httpApi.deferDeployment
      disable_execute_api_endpoint = var.stack.httpApi.disableExecuteApiEndpoint
      default_authorizer = var.stack.httpApi.defaultAuthorizer
      authorizers = try(var.stack.httpApi.authorizers, null) != null ? {
        for name, authorizer in var.stack.httpApi.authorizers : name => {
          type = authorizer.type
          identity_source = authorizer.identitySource
          ttl_in_seconds = authorizer.ttlInSeconds

          # request authorizer
          function_id = authorizer.functionId
          function_name = authorizer.functionName

          # jwt authorizer
          issuer = authorizer.issuer
          audience = authorizer.audience

          security_scheme = authorizer.securityScheme
        }
      } : null
      monitoring = {
        for metric_type, metric_config in coalesce(var.stack.httpApi.monitoring, {}) : lookup(local.camel_to_snake, metric_type, metric_type) => {
          for route_or_api, route_or_api_config in coalesce(metric_config, {}) : lookup(local.camel_to_snake, route_or_api, route_or_api) => {
            static = {
              for key, value in try(route_or_api_config.static, {}) : lookup(local.camel_to_snake, key, key) => {
                enabled            = try(value.enabled, false)
                threshold          = try(value.threshold, null)
                period             = try(value.period, null)
                evaluation_periods = try(value.evaluationPeriods, null)
              }
            }
            anomaly = {
              for key, value in try(route_or_api_config.anomaly, {}) : lookup(local.camel_to_snake, key, key) => {
                enabled = try(value.enabled, false)
                evaluation_periods              = try(value.evaluationPeriods, null)
                datapoints_to_alarm             = try(value.datapointsToAlarm, null)
                band_width_standard_deviations  = try(value.bandWidthStandardDeviations, null)
                metric_period                   = try(value.metricPeriod, null)
              }
            }
          }
        }
      }
    } : null
    rest_api = var.stack.restApi != null ? {
      name = var.stack.restApi.name
      defer_deployment = var.stack.restApi.deferDeployment
      disable_execute_api_endpoint = var.stack.restApi.disableExecuteApiEndpoint
      default_authorizer = var.stack.restApi.defaultAuthorizer
      authorizers = try(var.stack.restApi.authorizers, null) != null ? {
        for name, authorizer in var.stack.restApi.authorizers : name => {
          type = authorizer.type
          identity_source = authorizer.identitySource
          ttl_in_seconds = authorizer.ttlInSeconds

          # request authorizer
          function_id = authorizer.functionId
          function_name = authorizer.functionName

          security_scheme = authorizer.securityScheme
        }
      } : null
      monitoring = {
        for metric_type, metric_config in coalesce(var.stack.restApi.monitoring, {}) : lookup(local.camel_to_snake, metric_type, metric_type) => {
          for route_or_api, route_or_api_config in coalesce(metric_config, {}) : lookup(local.camel_to_snake, route_or_api, route_or_api) => {
            static = {
              for key, value in try(route_or_api_config.static, {}) : lookup(local.camel_to_snake, key, key) => {
                enabled            = try(value.enabled, false)
                threshold          = try(value.threshold, null)
                period             = try(value.period, null)
                evaluation_periods = try(value.evaluationPeriods, null)
              }
            }
            anomaly = {
              for key, value in try(route_or_api_config.anomaly, {}) : lookup(local.camel_to_snake, key, key) => {
                enabled = try(value.enabled, false)
                evaluation_periods              = try(value.evaluationPeriods, null)
                datapoints_to_alarm             = try(value.datapointsToAlarm, null)
                band_width_standard_deviations  = try(value.bandWidthStandardDeviations, null)
                metric_period                   = try(value.metricPeriod, null)
              }
            }
          }
        }
      }
    } : null
    lambda = var.stack.lambda != null ? {
      runtime = var.stack.lambda.runtime
      memory_size = var.stack.lambda.memorySize
      timeout = var.stack.lambda.timeout
      handler = var.stack.lambda.handler
      vpc_config = var.stack.lambda.vpcConfig
      environment = var.stack.lambda.environment
      inline_policies = var.stack.lambda.inlinePolicies
      functions_dir = var.stack.lambda.functionsDir
      function_prefix = var.stack.lambda.functionPrefix
      handler_file = var.stack.lambda.handlerFile
      # currently not supported
      local_artifact = null
    } : null
  } : null
}
