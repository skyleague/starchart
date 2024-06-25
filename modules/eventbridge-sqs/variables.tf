variable "eventbridge_to_sqs" {
  type = map(object({
    event_bus_name = string
    event_pattern  = string
  }))
  description = "The EventBridge events to be forwarded to SQS queues. Keys are the queue IDs."
}

variable "sqs" {
  type = map(object({
    queue = object({
      arn               = string
      url               = string
      kms_master_key_id = string
    })
  }))
  description = "The deployed SQS queues. Keys are the queue IDs."
}
