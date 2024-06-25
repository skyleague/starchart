

variable "queue_settings" {
  type = map(object({
    name                              = optional(string)
    name_prefix                       = optional(string)
    visibility_timeout_seconds        = optional(number)
    max_message_size                  = optional(number)
    delay_seconds                     = optional(number)
    message_retention_seconds         = optional(number)
    receive_wait_time_seconds         = optional(number)
    policy                            = optional(string)
    kms_master_key_id                 = optional(string)
    kms_data_key_reuse_period_seconds = optional(number)
    tags                              = optional(map(string))

    fifo = optional(object({
      enabled                     = optional(bool)
      content_based_deduplication = optional(bool)
      deduplication_scope         = optional(string)
      throughput_limit            = optional(string)
    }))

    dlq = optional(object({
      enabled           = optional(bool)
      suffix            = optional(string)
      max_receive_count = optional(number)
      redrive_enabled   = optional(bool)

      visibility_timeout_seconds = optional(number)
      message_retention_seconds  = optional(number)
      delay_seconds              = optional(number)
      receive_wait_time_seconds  = optional(number)
      policy                     = optional(string)
    }))
  }))

  description = "The settings for the queues."
  default     = {}
}


locals {
  queue_settings = coalesce(try(var.queue_settings, null), {})
  handlers = [
    for f in fileset(var.functions_dir, "**/${var.handler_file}") : yamldecode(
      file("${var.functions_dir}/${f}")
    )
  ]
  queue_ids = distinct(
    concat(
      flatten([for definition in local.handlers : [
        for event in try(definition.events, []) : event.sqs.queueId if try(event.sqs, null) != null
      ]]),
      keys(local.queue_settings)
    )
  )
  handler_events = {
    for queue_id in local.queue_ids : queue_id => flatten([
      for definition in local.handlers : [
        for event in try(definition.events, []) : {
          sqs = {
            for k, v in event.sqs : k => v if k != "queueId"
          }
          timeout = try(definition.timeout, 30)
        } if try(event.sqs.queueId, null) == queue_id
      ]
    ])
  }
  duplicate_queue_ids = [
    for queue_id, events in local.handler_events : queue_id if length(events) > 1
  ]
  handler_queue_settings = {
    for queue_id, events in local.handler_events : queue_id => events[0] if try(events[0], null) != null
  }
  queue_names = {
    for queue_id in local.queue_ids : queue_id => try(
      coalesce(
        try(local.queue_settings[queue_id].name, null),
        try(local.handler_queue_settings[queue_id].sqs.name, null)
      ),
      null
    )
  }
  queue_name_prefixes = {
    for queue_id in local.queue_ids : queue_id => local.queue_names[queue_id] == null ? (
      coalesce(
        try(local.queue_settings[queue_id].name_prefix, null),
        try(local.handler_queue_settings[queue_id].sqs.namePrefix, null),
        queue_id
      )
    ) : null
  }
  sqs_config = {
    for queue_id in local.queue_ids : queue_id => merge(
      {
        name_prefix = local.queue_name_prefixes[queue_id]
        name        = local.queue_names[queue_id]
      },
      # Settings with custom defaults
      {
        visibility_timeout_seconds = coalesce(
          try(local.queue_settings[queue_id].visibility_timeout_seconds, null),
          try(local.handler_queue_settings[queue_id].sqs.visibilityTimeoutSeconds, null),
          try(try(local.handler_queue_settings[queue_id].timeout, 30) + 30, null),
          30
        )
        message_retention_seconds = coalesce(
          try(local.queue_settings[queue_id].message_retention_seconds, null),
          try(local.handler_queue_settings[queue_id].sqs.messageRetentionSeconds, null),
          1209600
        )
        kms_master_key_id = coalesce(
          try(local.queue_settings[queue_id].kms_master_key_id, null),
          try(local.handler_queue_settings[queue_id].sqs.kmsMasterKeyId, null),
          try(local.handler_queue_settings[queue_id].sqs.eventbridge, null) != null ? var.eventbridge_kms_key_id : "alias/aws/sqs"
        )
      },
      # Settings with no custom defaults
      {
        for sk, ck in {
          max_message_size                  = "maxMessageSize"
          delay_seconds                     = "delaySeconds"
          receive_wait_time_seconds         = "receiveWaitTimeSeconds"
          policy                            = "policy"
          kms_data_key_reuse_period_seconds = "kmsDataKeyReusePeriodSeconds"
          tags                              = "tags"
          } : sk => try(
          coalesce(
            try(local.queue_settings[queue_id][sk], null),
            try(local.handler_queue_settings[queue_id].sqs[ck], null)
          ),
          null
        )
      },
      # FIFO settings and DLQ settings
      {
        fifo = try(local.queue_settings[queue_id].fifo.enabled, local.handler_queue_settings[queue_id].sqs.fifo.enabled, false) == true ? {
          for k, v in merge({ enabled = true }, {
            for sk, ck in {
              content_based_deduplication = "contentBasedDeduplication"
              deduplication_scope         = "deduplicationScope"
              throughput_limit            = "throughputLimit"
              } : sk => try(
              coalesce(
                try(local.queue_settings[queue_id].fifo[sk], null),
                try(local.handler_queue_settings[queue_id].sqs.fifo[ck], null)
              ),
              null
            )
          }) : k => v if v != null # Omit null values
        } : null

        dlq = try(local.queue_settings[queue_id].dlq.enabled, local.handler_queue_settings[queue_id].sqs.dlq.enabled, true) == true ? {
          for k, v in merge({ enabled = true }, {
            for sk, ck in {
              suffix                     = "suffix"
              max_receive_count          = "maxReceiveCount"
              redrive_enabled            = "redriveEnabled"
              visibility_timeout_seconds = "visibilityTimeoutSeconds"
              message_retention_seconds  = "messageRetentionSeconds"
              delay_seconds              = "delaySeconds"
              receive_wait_time_seconds  = "receiveWaitTimeSeconds"
              policy                     = "policy"
              } : sk => try(
              coalesce(
                try(local.queue_settings[queue_id].dlq[sk], null),
                try(local.handler_queue_settings[queue_id].sqs.dlq[ck], null)
              ),
              null
            )
          }) : k => v if v != null # Omit null values
        } : null
      }
    )
  }
}

output "sqs_config" {
  value = local.sqs_config

  precondition {
    condition     = length(local.duplicate_queue_ids) == 0
    error_message = "Multiple handlers are configured to use the same queue, for the following queueIds: [${join(", ", local.duplicate_queue_ids)}]"
  }
}
