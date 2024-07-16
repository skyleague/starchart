variable "persistent_queues" {
  type = map(object({
    queue = object({ name = optional(string), name_prefix = optional(string), arn = string, url = string, kms_master_key_id = string, visibility_timeout_seconds = number })
    dlq   = optional(object({ name = optional(string), name_prefix = optional(string), arn = string, url = string, kms_master_key_id = string, visibility_timeout_seconds = number }))
  }))

  description = "The queues created by the persistent stack."
  default     = {}
  nullable    = false
}


locals {
  handlers = [
    for f in fileset(var.functions_dir, "**/${var.handler_file}") : yamldecode(
      file("${var.functions_dir}/${f}")
    )
  ]
  queue_ids = toset(flatten([for definition in local.handlers : [
    for event in try(definition.events, []) : event.sqs.queueId if try(event.sqs, null) != null
  ]]))

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
      try(local.handler_queue_settings[queue_id].sqs.name, null),
      null
    )
  }
  queue_name_prefixes = {
    for queue_id in local.queue_ids : queue_id => local.queue_names[queue_id] == null ? (
      coalesce(
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
          try(local.handler_queue_settings[queue_id].sqs.visibilityTimeoutSeconds, null),
          try(try(local.handler_queue_settings[queue_id].timeout, 30) + 30, null),
          30
        )
        message_retention_seconds = coalesce(
          try(local.handler_queue_settings[queue_id].sqs.messageRetentionSeconds, null),
          1209600
        )
        kms_master_key_id = coalesce(
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
            try(local.handler_queue_settings[queue_id].sqs[ck], null)
          ),
          null
        )
      },
      # FIFO settings and DLQ settings
      {
        fifo = try(local.handler_queue_settings[queue_id].sqs.fifo.enabled, false) == true ? {
          for k, v in merge({ enabled = true }, {
            for sk, ck in {
              content_based_deduplication = "contentBasedDeduplication"
              deduplication_scope         = "deduplicationScope"
              throughput_limit            = "throughputLimit"
            } : sk => try(local.handler_queue_settings[queue_id].sqs.fifo[ck], null)
          }) : k => v if v != null # Omit null values
        } : null

        dlq = try(local.handler_queue_settings[queue_id].sqs.dlq.enabled, true) == true ? {
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
            } : sk => try(local.handler_queue_settings[queue_id].sqs.dlq[ck], null)
          }) : k => v if v != null # Omit null values
        } : null
      }
    ) if try(var.persistent_queues[queue_id], null) == null
  }
}

output "sqs_config" {
  value = local.sqs_config

  precondition {
    condition     = length(local.duplicate_queue_ids) == 0
    error_message = "Multiple handlers are configured to use the same queue, for the following queueIds: [${join(", ", local.duplicate_queue_ids)}]"
  }
}
