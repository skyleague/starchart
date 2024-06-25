variable "resources" {
  type = object({
    dynamodb = optional(map(object({ arn = string, id = string })), {})
    appconfig = optional(object({
      application_id         = string,
      configuration_profiles = map(object({ configuration_profile_id = string })),
      environments           = map(object({ environment_id = string }))
    }))
    eventbridge = optional(map(object({ arn = string, id = string })), {})

    secrets        = optional(map(object({ arn = string })), {})
    ssm_parameters = optional(map(object({ arn = string })), {})
    s3             = optional(map(object({ arn = string, id = string })), {})
  })
  default = {}

  description = "The resources that can possibly be used by the functions."
}

locals {
  _resources = {
    secrets = merge(local.persistent.secrets, coalesce(var.resources.secrets, {}), [
      for stack, starchart in var.starchart.stacks : {
        for id, resource in starchart.persistent.secrets : "${stack}:${id}" => resource
      }]...
    )
    ssm_parameters = merge(local.persistent.ssm_parameters, coalesce(var.resources.ssm_parameters, {}), [
      for stack, starchart in var.starchart.stacks : {
        for id, resource in starchart.persistent.ssm_parameters : "${stack}:${id}" => resource
    }]...)
    s3 = merge(local.persistent.s3, coalesce(var.resources.s3, {}), [
      for stack, starchart in var.starchart.stacks : {
        for id, resource in starchart.persistent.s3 : "${stack}:${id}" => resource
    }]...)
    dynamodb = merge(local.persistent.dynamodb, coalesce(var.resources.dynamodb, {}), [
      for stack, starchart in var.starchart.stacks : {
        for id, resource in starchart.persistent.dynamodb : "${stack}:${id}" => resource
    }]...)
    eventbridge = merge(local.persistent.eventbridge, coalesce(var.resources.eventbridge, {}), [
      for stack, starchart in var.starchart.stacks : {
        for id, resource in starchart.persistent.eventbridge : "${stack}:${id}" => resource
    }]...)
    appconfig = {
      configuration_profiles = merge(local.persistent.appconfig.configuration_profiles, try(var.resources.appconfig.configuration_profiles, {}))
      environments           = merge(local.persistent.appconfig.environments, try(var.resources.appconfig.environments, {}))
    }
  }
  resources = {
    s3 = {
      for bucketId, resource in local._resources.s3 : bucketId => {
        arn = resource.arn
        id  = resource.id
        env = { "STARCHART_S3_${upper(replace(bucketId, "/[^a-zA-Z0-9]+/", "_"))}_BUCKET_NAME" = resource.id }
      }
    }
    dynamodb = {
      for tableId, resource in local._resources.dynamodb : tableId => {
        arn = resource.arn
        id  = resource.id
        env = { "STARCHART_DYNAMODB_${upper(replace(tableId, "/[^a-zA-Z0-9]+/", "_"))}_TABLE_NAME" = resource.id }
      }
    }
    eventbridge = {
      for eventBusId, resource in local._resources.eventbridge : eventBusId => {
        arn = resource.arn
        id  = resource.id
        env = { "STARCHART_EVENTBRIDGE_${upper(replace(eventBusId, "/[^a-zA-Z0-9]+/", "_"))}" = resource.id }
      }

    }
    secrets        = local._resources.secrets
    ssm_parameters = local._resources.ssm_parameters
    appconfig      = local._resources.appconfig
  }
}

output "resources" {
  value = local.resources
}

