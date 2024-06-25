variable "resources" {
  type = object({
    secrets        = optional(map(object({ arn = string })), {})
    ssm_parameters = optional(map(object({ arn = string })), {})
    s3             = optional(map(object({ arn = string, id = string, env = map(string) })), {})
    dynamodb       = optional(map(object({ arn = string, id = string, env = map(string) })), {})
    eventbridge    = optional(map(object({ arn = string, id = string, env = map(string) })), {})

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
  function_resources = {
    for function_id, definition in local.handlers : function_id => {
      secrets = [
        for resource in try(definition.resources, []) : {
          path           = try(resource.secret.path, resource.secret)
          actions        = try(resource.secret.actions, ["read"])
          actions_string = join(",", sort(toset(try(resource.secret.actions, ["read"]))))
        } if try(resource.secret, null) != null
      ]
      ssm_parameters = [
        for resource in try(definition.resources, []) : {
          path           = try(resource.parameter.path, resource.parameter)
          actions        = try(resource.parameter.actions, ["read"])
          actions_string = join(",", sort(toset(try(resource.parameter.actions, ["read"]))))
        } if try(resource.parameter, null) != null
      ]
      s3 = [
        for resource in try(definition.resources, []) : {
          bucketId       = resource.s3.bucketId
          actions        = resource.s3.actions
          actions_string = join(",", sort(toset(resource.s3.actions)))
        } if try(resource.s3, null) != null
      ]
      dynamodb = [
        for resource in try(definition.resources, []) : {
          tableId        = resource.dynamodb.tableId
          actions        = resource.dynamodb.actions
          actions_string = join(",", sort(toset(resource.dynamodb.actions)))
        } if try(resource.dynamodb, null) != null
      ]
      appconfig = concat(try(var.resources.appconfig.configuration_profiles.default, null) != null ? [{ configuration_profile_id = "default" }] : [], [
        # TODO: Add support for multiple configuration profiles
      ])
    }
  }
}

data "aws_iam_policy_document" "secrets_access" {
  for_each = { for function_id, definition in local.function_resources : function_id => definition.secrets if length(try(definition.secrets, [])) > 0 }

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
        for secret in each.value : var.resources.secrets[secret.path].arn if secret.actions_string == statement.key
      ]
    }
  }
}

data "aws_iam_policy_document" "ssm_parameters_access" {
  for_each = { for function_id, definition in local.function_resources : function_id => definition.ssm_parameters if length(try(definition.ssm_parameters, [])) > 0 }

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
        for parameter in each.value : var.resources.ssm_parameters[parameter.path].arn if parameter.actions_string == statement.key
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
        [bucket.actions]
      )
    ]...)

    content {
      effect = "Allow"

      actions = toset(concat(
        anytrue([for action in ["read", "get"] : contains(statement.value, action)]) ? [
          "s3:GetObject",
        ] : [],
        anytrue([for action in ["read", "list"] : contains(statement.value, action)]) ? [
          "s3:ListBucket",
        ] : [],
        contains(statement.value, "write") ? [
          "s3:PutObject",
        ] : [],
        contains(statement.value, "delete") ? [
          "s3:DeleteObject",
        ] : [],
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
        [table.actions]
      )
    ]...)

    content {
      effect = "Allow"

      actions = toset(concat(
        anytrue([for action in ["read", "get"] : contains(statement.value, action)]) ? [
          "dynamodb:GetItem",
        ] : [],
        anytrue([for action in ["read", "query"] : contains(statement.value, action)]) ? [
          "dynamodb:Query",
        ] : [],
        anytrue([for action in ["write", "put"] : contains(statement.value, action)]) ? [
          "dynamodb:PutItem",
        ] : [],
        anytrue([for action in ["write", "update"] : contains(statement.value, action)]) ? [
          "dynamodb:UpdateItem",
        ] : [],
        contains(statement.value, "delete") ? [
          "dynamodb:DeleteItem",
        ] : [],
        contains(statement.value, "scan") ? [
          "dynamodb:Scan",
        ] : [],
      ))

      resources = [
        for table in each.value : var.resources.dynamodb[table.tableId].arn if table.actions_string == statement.key
      ]
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

output "resources_env" {
  value = local.resources_env
}
