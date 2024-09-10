variable "lambda" {
  type    = any
  default = {}
}

module "lambda_settings" {
  source = "./lambda-settings"

  runtime     = try(local.starchart.stack.lambda.runtime, var.lambda.runtime)
  memory_size = try(local.starchart.stack.lambda.memorySize, var.lambda.memory_size, 1024)
  timeout     = try(local.starchart.stack.lambda.timeout, var.lambda.timeout, 20)
  handler     = try(local.starchart.stack.lambda.handler, var.lambda.handler, null)
  vpc_config  = try(local.starchart.stack.lambda.vpcConfig, var.lambda.vpc_config, null)


  environment = merge(
    try(local.starchart.stack.lambda.environment, {}),
    try(var.lambda.environment, {})
  )
  inline_policies = merge(
    try(local.starchart.stack.lambda.inlinePolicies, {}),
    try(var.lambda.inline_policies, {})
  )

  functions_dir   = try(var.lambda.functions_dir, local.starchart.stack.path)
  function_prefix = try(var.lambda.function_prefix, "${local.config.stack}-")
  handler_file    = try(var.lambda.handler_file, null)


  local_artifact = try(local.starchart.stack.lambda.localArtifact, var.lambda.local_artifact, {})
}

locals {
  # convert this to a proper setting
  local_artifact_path_prefix = coalesce(module.lambda_settings.local_artifact.path_prefix, "${local.config.repo_root}/.artifacts/${replace(module.lambda_settings.functions_dir, local.config.repo_root, "")}")
}


module "config_lambda" {
  source = "../modules/config-lambda"

  functions_dir = "${local.starchart.config.repo_root}/${module.lambda_settings.functions_dir}"
  handler_file  = module.lambda_settings.handler_file

  function_prefix    = module.lambda_settings.function_prefix
  template_variables = merge(var.template_variables, { param = try(local.starchart.param, null) })

  appconfig_application_arn = local.bootstrap.appconfig.application.arn

  resources = local.resources

  inline_policies = merge(var.inline_policies, [
    # for queue_id, queue in module.sqs : {
    #   for policy_id, policy in queue.policies : replace("${queue_id}_${policy_id}", "/[^a-zA-Z0-9]+/", "_") => policy
    # }
  ]...)
}

module "lambda" {
  source = "git::https://github.com/skyleague/aws-lambda.git?ref=v2.2.0"

  for_each = module.config_lambda.lambda_definitions

  function_name = each.value.function_name

  runtime     = coalesce(each.value.runtime, module.lambda_settings.runtime)
  memory_size = coalesce(each.value.memory_size, module.lambda_settings.memory_size)
  timeout     = coalesce(each.value.timeout, module.lambda_settings.timeout)
  handler     = coalesce(each.value.handler, module.lambda_settings.handler)
  vpc_config  = try(each.value.vpc_config, module.lambda_settings.vpc_config, null)

  environment     = merge(module.lambda_settings.environment, each.value.environment)
  inline_policies = merge(module.lambda_settings.inline_policies, each.value.inline_policies)

  # when we support s3 artifacts, we need to change the default logic
  local_artifact = module.lambda_settings.local_artifact == null ? null : {
    type      = module.lambda_settings.local_artifact.type
    path      = "${local.local_artifact_path_prefix}${each.value.artifact_path}${module.lambda_settings.local_artifact.type == "zip" ? ".zip" : ""}"
    s3_bucket = try(module.lambda_settings.local_artifact.s3_bucket, local.bootstrap.artifacts_bucket.id)
    s3_prefix = module.lambda_settings.local_artifact.s3_prefix
  }

  tags = {
    Path = "/${module.lambda_settings.functions_dir}${each.value.artifact_path}/${split(".", coalesce(each.value.handler, module.lambda_settings.handler, "index.handler"))[0]}"
  }
}

locals {
  _cloudwatch_lambda = {
    for function_id, lambda in module.lambda : function_id => {
      name = lambda.log_group.name
      arn  = lambda.log_group.arn
    }
  }
}

output "lambdas" {
  value = {
    for key, lambda in module.config_lambda.lambda_definitions : key => {
      function_name = lambda.function_name
      # arn           = lambda.arn
    }
  }
}

# output "config_lambda" {
#   value = module.config_lambda
# }
