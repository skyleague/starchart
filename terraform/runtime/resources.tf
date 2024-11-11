variable "resources" {
  type = object({
    dynamodb = optional(map(object({ arn = string, id = string })), {})
    appconfig = optional(object({
      application_id         = string,
      configuration_profiles = map(object({ configuration_profile_id = string })),
      environments           = map(object({ environment_id = string }))
    }))
    eventbridge = optional(map(object({ arn = string, id = string })), {})

    secret        = optional(map(object({ arn = string })), {})
    ssm_parameter = optional(map(object({ arn = string })), {})
    s3            = optional(map(object({ arn = string, id = string })), {})
    sqs = optional(map(object({
      queue = object({ name = optional(string), name_prefix = optional(string), arn = string, url = string, kms_master_key_id = string, visibility_timeout_seconds = number })
      dlq   = optional(object({ name = optional(string), name_prefix = optional(string), arn = string, url = string, kms_master_key_id = string, visibility_timeout_seconds = number }))
    })), {})
  })
  default = {}

  description = "The resources that can possibly be used by the functions."
}

locals {
  _resources = {
    secret = merge(try(local.persistent.secret, {}), coalesce(var.resources.secret, {}), [
      for stack, starchart in local.starchart.stacks : {
        for id, resource in starchart.persistent.secret : "${stack}:${id}" => resource
      }]...
    )
    ssm_parameter = merge(try(local.persistent.ssm_parameter, {}), coalesce(var.resources.ssm_parameter, {}), [
      for stack, starchart in local.starchart.stacks : {
        for id, resource in starchart.persistent.ssm_parameter : "${stack}:${id}" => resource
    }]...)
    s3 = merge(try(local.persistent.s3, {}), coalesce(var.resources.s3, {}), [
      for stack, starchart in local.starchart.stacks : {
        for id, resource in starchart.persistent.s3 : "${stack}:${id}" => resource
    }]...)
    dynamodb = merge(try(local.persistent.dynamodb, {}), coalesce(var.resources.dynamodb, {}), [
      for stack, starchart in local.starchart.stacks : {
        for id, resource in starchart.persistent.dynamodb : "${stack}:${id}" => resource
    }]...)
    eventbridge = merge(try(local.persistent.eventbridge, {}), coalesce(var.resources.eventbridge, {}), [
      for stack, starchart in local.starchart.stacks : {
        for id, resource in starchart.persistent.eventbridge : "${stack}:${id}" => resource
    }]...)
    sqs = merge(try(local.persistent.sqs, {}), module.sqs, coalesce(var.resources.sqs, {}), [
      for stack, starchart in local.starchart.stacks : {
        for id, resource in starchart.persistent.sqs : "${stack}:${id}" => resource
    }]...)
    appconfig = {
      configuration_profiles = merge(try(local.persistent.appconfig.configuration_profiles, {}), try(var.resources.appconfig.configuration_profiles, {}))
      environments           = merge(try(local.persistent.appconfig.environments, {}), try(var.resources.appconfig.environments, {}))
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
    sqs_queue = {
      for queueId, resource in local._resources.sqs : queueId => {
        name                       = resource.queue.name
        name_prefix                = resource.queue.name_prefix
        arn                        = resource.queue.arn
        url                        = resource.queue.url
        kms_master_key_id          = resource.queue.kms_master_key_id
        visibility_timeout_seconds = resource.queue.visibility_timeout_seconds
        env                        = { "STARCHART_SQS_${upper(replace(queueId, "/[^a-zA-Z0-9]+/", "_"))}_QUEUE_URL" = resource.queue.url }
      }
    }
    sqs_dlq = {
      for dlqId, resource in local._resources.sqs : dlqId => {
        name                       = resource.dlq.name
        name_prefix                = resource.dlq.name_prefix
        arn                        = resource.dlq.arn
        url                        = resource.dlq.url
        kms_master_key_id          = resource.dlq.kms_master_key_id
        visibility_timeout_seconds = resource.dlq.visibility_timeout_seconds
        env                        = { "STARCHART_SQS_${upper(replace(dlqId, "/[^a-zA-Z0-9]+/", "_"))}_DLQ_URL" = resource.dlq.url }
      } if try(resource.dlq, null) != null
    }
    secret        = local._resources.secret
    ssm_parameter = local._resources.ssm_parameter
    appconfig     = local._resources.appconfig
  }
}

output "resources" {
  value = local.resources
}

