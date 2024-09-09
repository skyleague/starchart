variable "resources" {
  type = object({
    secret        = optional(map(object({ arn = string })), {})
    ssm_parameter = optional(map(object({ arn = string })), {})
    s3            = optional(map(object({ arn = string, id = string, env = map(string) })), {})
    dynamodb      = optional(map(object({ arn = string, id = string, env = map(string) })), {})
    eventbridge   = optional(map(object({ arn = string, id = string, env = map(string) })), {})
    sqs_queue     = optional(map(object({ name = optional(string), name_prefix = optional(string), arn = string, url = string, kms_master_key_id = string, visibility_timeout_seconds = number, env = map(string) })), {})
    sqs_dlq       = optional(map(object({ name = optional(string), name_prefix = optional(string), arn = string, url = string, kms_master_key_id = string, visibility_timeout_seconds = number, env = map(string) })), {})

    appconfig = optional(object({
      configuration_profiles = map(object({ configuration_profile_id = string })),
      environments           = map(object({ environment_id = string }))
      }), {
      configuration_profiles = {},
      environments           = {},
    })

  })
  default = {}

  description = "The resources that can possibly be used by the functions."
}

variable "function_resources" {
  type = any
}

locals {
  resources_env = merge(flatten([
    for resource_type, resources in var.resources : [
      for resource_id, resource in resources : resource.env
      if try(resource.env, null) != null
    ]
  ])...)
}

variable "appconfig_application_arn" {
  type = string
}

locals {
  function_resources = var.function_resources
}

data "aws_iam_policy_document" "secrets_access" {
  for_each = { for function_id, definition in local.function_resources : function_id => definition.secret if length(try(definition.secret, [])) > 0 }

  dynamic "statement" {
    for_each = merge([
      for secret in each.value : zipmap(
        [secret.actions_string],
        [secret.actions]
      )
    ]...)

    content {
      effect = "Allow"

      actions = toset(concat(
        contains(statement.value, "read") ? [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret",
          "secretsmanager:ListSecretVersionIds",
        ] : [],
        contains(statement.value, "rotation") ? [
          "secretsmanager:DescribeSecret",
          "secretsmanager:GetSecretValue",
          "secretsmanager:PutSecretValue",
          "secretsmanager:UpdateSecretVersionStage",
        ] : [],
      ))

      resources = [
        for secret in each.value : var.resources.secret[secret.path].arn if secret.actions_string == statement.key
      ]
    }
  }
}

data "aws_iam_policy_document" "ssm_parameters_access" {
  for_each = { for function_id, definition in local.function_resources : function_id => definition.ssm_parameter if length(try(definition.ssm_parameter, [])) > 0 }

  dynamic "statement" {
    for_each = merge([
      for parameter in each.value : zipmap(
        [parameter.actions_string],
        [parameter.actions]
      )
    ]...)

    content {
      effect = "Allow"

      actions = toset(concat(
        contains(statement.value, "read") ? [
          "ssm:GetParameter",
          "ssm:GetParameters",
          "ssm:GetParametersByPath",
        ] : [],
      ))

      resources = [
        for parameter in each.value : var.resources.ssm_parameter[parameter.path].arn if parameter.actions_string == statement.key
      ]
    }
  }
}

data "aws_iam_policy_document" "s3_access" {
  for_each = { for function_id, definition in local.function_resources : function_id => definition.s3 if length(try(definition.s3, [])) > 0 }

  dynamic "statement" {
    for_each = merge([
      for bucket in each.value : zipmap(
        [bucket.actions_string],
        [{ actions = bucket.actions, iam_actions = bucket.iam_actions }]
      )
    ]...)

    content {
      effect = "Allow"

      actions = toset(concat(
        anytrue([for action in ["read", "get"] : contains(statement.value.actions, action)]) ? [
          "s3:GetObject",
        ] : [],
        anytrue([for action in ["read", "list"] : contains(statement.value.actions, action)]) ? [
          "s3:ListBucket",
        ] : [],
        contains(statement.value.actions, "write") ? [
          "s3:PutObject",
        ] : [],
        contains(statement.value.actions, "delete") ? [
          "s3:DeleteObject",
        ] : [],
        statement.value.iam_actions,
      ))

      resources = flatten([
        for arn in [for bucket in each.value : var.resources.s3[bucket.bucketId].arn if bucket.actions_string == statement.key] : [
          arn,
          "${arn}/*",
        ]
      ])
    }
  }
}

data "aws_iam_policy_document" "dynamodb_access" {
  for_each = { for function_id, definition in local.function_resources : function_id => definition.dynamodb if length(try(definition.dynamodb, [])) > 0 }

  dynamic "statement" {
    for_each = merge([
      for table in each.value : zipmap(
        [table.actions_string],
        [{ actions = table.actions, iam_actions = table.iam_actions }]
      )
    ]...)

    content {
      effect = "Allow"

      actions = toset(concat(
        anytrue([for action in ["read", "get"] : contains(statement.value.actions, action)]) ? [
          "dynamodb:GetItem",
        ] : [],
        anytrue([for action in ["read", "query"] : contains(statement.value.actions, action)]) ? [
          "dynamodb:Query",
        ] : [],
        anytrue([for action in ["write", "put"] : contains(statement.value.actions, action)]) ? [
          "dynamodb:PutItem",
        ] : [],
        anytrue([for action in ["write", "update"] : contains(statement.value.actions, action)]) ? [
          "dynamodb:UpdateItem",
        ] : [],
        contains(statement.value.actions, "delete") ? [
          "dynamodb:DeleteItem",
        ] : [],
        contains(statement.value.actions, "scan") ? [
          "dynamodb:Scan",
        ] : [],
        statement.value.iam_actions,
      ))

      resources = flatten([
        for arn in [for table in each.value : var.resources.dynamodb[table.tableId].arn if table.actions_string == statement.key] : [
          arn,
          "${arn}/index/*",
        ]
      ])
    }
  }
}

data "aws_iam_policy_document" "appconfig_configuration_profile_access" {
  for_each = { for function_id, definition in local.function_resources : function_id => definition.appconfig if length(try(definition.appconfig, [])) > 0 }
  statement {
    effect = "Allow"
    actions = [
      "appconfig:GetLatestConfiguration",
      "appconfig:StartConfigurationSession",
    ]
    resources = flatten([
      for appconfig in [for profile in each.value : var.resources.appconfig.configuration_profiles[profile.configuration_profile_id]] : [
        # todo add support for multiple configuration profiles
        "${var.appconfig_application_arn}/*",
      ]
    ])
  }
}

data "aws_iam_policy_document" "custom_access" {
  for_each = { for function_id, definition in local.function_resources : function_id => definition.custom if length(try(definition.custom, [])) > 0 }

  dynamic "statement" {
    for_each = merge([
      for custom in each.value : zipmap(
        [custom.iam_actions_string],
        [custom.iam_actions]
      )
    ]...)

    content {
      effect = "Allow"

      actions = statement.value

      resources = flatten([
        for custom in each.value : custom.arn if custom.iam_actions_string == statement.key
      ])
    }

  }
}

output "resources_env" {
  value = local.resources_env
}
