locals {
  publishes = {
    for function_id, definition in local.handlers : function_id => {
      eventbridge = [for event in try(definition.publishes, []) : event.eventbridge if try(event.eventbridge, null) != null]
      sqs         = [for event in try(definition.publishes, []) : event.sqs if try(event.sqs, null) != null]
    }
  }
}

data "aws_iam_policy_document" "eventbridge_publish" {
  for_each = { for function_id, definition in local.publishes : function_id => definition.eventbridge if try(definition.eventbridge, null) != null }

  dynamic "statement" {
    for_each = toset(flatten([for topic in each.value : topic.eventBusId]))
    content {
      effect    = "Allow"
      actions   = ["events:PutEvents"]
      resources = [var.resources.eventbridge[statement.key].arn]
      condition {
        test     = "StringEquals"
        variable = "events:detail-type"
        values   = flatten([for topic in each.value : topic.detailType if topic.eventBusId == statement.key])
      }
      # @TODO
      # condition {
      #   test     = "StringEquals"
      #   variable = "events:source"
      #   values   = [var.eventbridge.publish_source]
      # }
    }
  }

  # lifecycle {
  #   precondition {
  #     condition     = try(var.eventbridge.publish_source, null) != null
  #     error_message = "The eventbridge_publish_source variable must be set."
  #   }
  # }
}

data "aws_iam_policy_document" "sqs_publish" {
  for_each = { for function_id, definition in local.publishes : function_id => definition.sqs if try(definition.sqs, null) != null }

  statement {
    effect = "Allow"

    actions = [
      "sqs:SendMessage",
      "sqs:GetQueueUrl",
    ]

    resources = [
      for queue in each.value : var.sqs[queue.queueId].queue.arn
    ]
  }

  dynamic "statement" {
    for_each = toset(flatten([for queue in each.value : var.sqs[queue.queueId].queue.kms_master_key_id if var.sqs[queue.queueId].queue.kms_master_key_id != "alias/aws/sqs"]))

    content {
      effect = "Allow"

      actions = [
        "kms:Decrypt",
        "kms:GenerateDataKey",
      ]

      resources = [statement.key]
    }
  }
}
