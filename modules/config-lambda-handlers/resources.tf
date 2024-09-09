variable "appconfig_application_arn" {
  type = string
}

variable "appconfig" {
  type = object({
    configuration_profiles = map(object({ configuration_profile_id = string })),
    environments           = map(object({ environment_id = string }))
  })

  nullable = false
  default = {
    configuration_profiles = {},
    environments           = {},
  }
}

locals {
  function_resources = {
    for function_id, definition in local.handlers : function_id => {
      secret = [
        for resource in try(definition.resources, []) : {
          path           = try(resource.secret.path, resource.secret)
          actions        = try(resource.secret.actions, ["read"])
          actions_string = join(",", sort(toset(try(resource.secret.actions, ["read"]))))
        } if try(resource.secret, null) != null
      ]
      ssm_parameter = [
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
          iam_actions    = try(flatten([resource.s3.iamActions]), [])
          actions_string = join(",", sort(toset(flatten([resource.s3.actions, try(resource.s3.iamActions, [])]))))
        } if try(resource.s3, null) != null
      ]
      dynamodb = [
        for resource in try(definition.resources, []) : {
          tableId        = resource.dynamodb.tableId
          actions        = resource.dynamodb.actions
          iam_actions    = try(flatten([resource.dynamodb.iamActions]), [])
          actions_string = join(",", sort(toset(flatten([resource.dynamodb.actions, try(resource.dynamodb.iamActions, [])]))))
        } if try(resource.dynamodb, null) != null
      ]
      custom = [
        for resource in try(definition.resources, []) : {
          arn                = resource.custom.arn
          iam_actions        = flatten([resource.custom.iamActions])
          iam_actions_string = join(",", sort(toset(flatten([resource.custom.iamActions]))))
        } if try(resource.custom, null) != null
      ]
      appconfig = concat(try(var.appconfig.configuration_profiles.default, null) != null ? [{ configuration_profile_id = "default" }] : [], [
        # TODO: Add support for multiple configuration profiles
      ])
    }
  }
}

output "function_resources" {
  value = local.function_resources
}
