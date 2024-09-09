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

module "config_lambda_handlers" {
  source = "../../modules/config-lambda-handlers"

  functions_dir = local.functions_dir
  handler_file  = local.handler_file

  function_prefix = local.function_prefix

  appconfig                 = local._resources.appconfig
  appconfig_application_arn = local.bootstrap.appconfig.application.arn
}

# output "config_lambda_handlers" {
#   value = module.config_lambda_handlers
# }

module "config_lambda" {
  source = "../modules/config-lambda"

  handlers           = module.config_lambda_handlers.handlers
  publishes          = module.config_lambda_handlers.publishes
  function_resources = module.config_lambda_handlers.function_resources

  template_variables = var.template_variables

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

  for_each = module.config_lambda_handlers.handlers
  # for_each = {}

  function_name = module.config_lambda.lambda_definitions[each.key].function_name

  runtime     = coalesce(module.config_lambda.lambda_definitions[each.key].runtime, var.lambda.runtime)
  vpc_config  = try(module.config_lambda.lambda_definitions[each.key].vpc_config, var.lambda.vpc_config, null)
  handler     = coalesce(module.config_lambda.lambda_definitions[each.key].handler, var.lambda.handler, "index.handler")
  memory_size = coalesce(module.config_lambda.lambda_definitions[each.key].memory_size, var.lambda.memory_size, 1024)
  timeout     = coalesce(module.config_lambda.lambda_definitions[each.key].timeout, var.lambda.timeout, 20)

  environment = merge(var.lambda.environment, module.config_lambda.lambda_definitions[each.key].environment)

  inline_policies = merge(var.lambda.inline_policies, module.config_lambda.lambda_definitions[each.key].inline_policies)

  local_artifact = var.lambda.local_artifact == null ? null : {
    type      = var.lambda.local_artifact.type
    path      = "${local.local_artifact_path_prefix}${module.config_lambda.lambda_definitions[each.key].artifact_path}${var.lambda.local_artifact.type == "zip" ? ".zip" : ""}"
    s3_bucket = try(var.lambda.local_artifact.s3_bucket, local.bootstrap.artifacts_bucket.id)
    s3_prefix = var.lambda.local_artifact.s3_prefix
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
