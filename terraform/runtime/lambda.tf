variable "lambda" {
  type = object({
    runtime = string

    functions_dir   = optional(string)
    function_prefix = optional(string)

    handler_file = optional(string)

    memory_size = optional(number)
    timeout     = optional(number)
    handler     = optional(string)
    environment = optional(map(string), {})

    inline_policies = optional(map(object({ json = string })), {})

    vpc_config = optional(any)

    local_artifact = optional(object({
      type        = optional(string, "zip")
      path_prefix = optional(string)
      s3_bucket   = optional(string)
      s3_prefix   = optional(string)
    }))
  })
}

locals {
  functions_dir              = coalesce(var.lambda.functions_dir, var.directory)
  function_prefix            = coalesce(var.lambda.function_prefix, "${local.config.stack}-")
  local_artifact_path_prefix = coalesce(var.lambda.local_artifact.path_prefix, "${local.config.repo_root}/.artifacts/${replace(local.functions_dir, "${local.config.repo_root}/src", "")}/")

  handler_file = coalesce(var.lambda.handler_file, "handler.yml")
}


module "config_lambda" {
  source = "../../modules/config-lambda"

  functions_dir = local.functions_dir
  handler_file  = local.handler_file

  function_prefix    = local.function_prefix
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
  source = "https://github.com/skyleague/aws-lambda.git?ref=v2.0.1"

  for_each = module.config_lambda.lambda_definitions

  function_name = each.value.function_name

  runtime     = coalesce(each.value.runtime, var.lambda.runtime)
  vpc_config  = try(each.value.vpc_config, var.lambda.vpc_config, null)
  handler     = coalesce(each.value.handler, var.lambda.handler, "index.handler")
  memory_size = coalesce(each.value.memory_size, var.lambda.memory_size, 1024)
  timeout     = coalesce(each.value.timeout, var.lambda.timeout, 20)

  environment = merge(var.lambda.environment, each.value.environment)

  inline_policies = merge(var.lambda.inline_policies, each.value.inline_policies)

  local_artifact = var.lambda.local_artifact == null ? null : {
    type      = var.lambda.local_artifact.type
    path      = "${local.local_artifact_path_prefix}${each.value.artifact_path}${var.lambda.local_artifact.type == "zip" ? ".zip" : ""}"
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

