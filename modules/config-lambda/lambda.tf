locals {
  lambda_definitions = {
    for function_id, definition in local.handlers : function_id => {
      function_name = definition.function_name
      artifact_path = definition.artifact_path

      handler     = try(definition.handler, null)
      runtime     = try(definition.runtime, null)
      timeout     = try(definition.timeout, null)
      memory_size = try(definition.memorySize, null)

      vpc_config = try(definition.vpcConfig, null)

      environment = merge(
        try(definition.environment, {}),
        merge([
          for resource in try(local.publishes[function_id].eventbridge, [])
          : var.resources.eventbridge[resource.eventBusId].env
        ]...),
        {
          for event in try(local.publishes[function_id].sqs, [])
          : "STARCHART_SQS_${upper(replace(event.queueId, "/[^a-zA-Z0-9]+/", "_"))}_QUEUE_URL" => var.sqs[event.queueId].queue.url
        },
        merge([
          for resource in try(local.function_resources[function_id].s3, [])
          : var.resources.s3[resource.bucketId].env
        ]...),

        merge([
          for resource in try(local.function_resources[function_id].dynamodb, [])
          : var.resources.dynamodb[resource.tableId].env
        ]...),
      )

      inline_policies = merge(
        { for k in try(definition.inlinePolicies, []) : k => try(var.inline_policies[k], null) },
        length(try(local.publishes[function_id].eventbridge, [])) == 0 ? {} : {
          starchart_eventbridge_publish = data.aws_iam_policy_document.eventbridge_publish[function_id]
        },
        length(try(local.publishes[function_id].sqs, [])) == 0 ? {} : {
          starchart_sqs_publish = data.aws_iam_policy_document.sqs_publish[function_id]
        },
        length(try(local.function_resources[function_id].s3, [])) == 0 ? {} : {
          starchart_s3_access = data.aws_iam_policy_document.s3_access[function_id]
        },
        length(try(local.function_resources[function_id].ssm_parameters, [])) == 0 ? {} : {
          starchart_ssm_access = data.aws_iam_policy_document.ssm_parameters_access[function_id]
        },
        length(try(local.function_resources[function_id].secrets, [])) == 0 ? {} : {
          starchart_secrets_access = data.aws_iam_policy_document.secrets_access[function_id]
        },
        length(try(local.function_resources[function_id].dynamodb, [])) == 0 ? {} : {
          starchart_dynamodb_access = data.aws_iam_policy_document.dynamodb_access[function_id]
        },
        length(try(local.function_resources[function_id].appconfig, [])) == 0 ? {} : {
          appconfig_configuration_profile_access = data.aws_iam_policy_document.appconfig_configuration_profile_access[function_id]
        },
      )
    }
  }
}

output "lambda_definitions" {
  value = local.lambda_definitions
}
