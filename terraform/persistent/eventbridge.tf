variable "eventbridge" {
  type = map(object({
    name = optional(string)
  }))
  description = "The EventBridge configuration to be used by StarChart."
  default     = {}
}

resource "aws_cloudwatch_event_bus" "bus" {
  for_each = var.eventbridge

  name = coalesce(each.value.name, "${local.config.stack_prefix}-${each.key}")
}

resource "aws_cloudwatch_event_archive" "bus" {
  for_each = aws_cloudwatch_event_bus.bus

  name             = each.value.name
  event_source_arn = each.value.arn
}

data "aws_iam_policy_document" "eventbridge_resource_policy" {
  for_each = aws_cloudwatch_event_bus.bus

  statement {
    sid    = "AllowAccountToPutEvents"
    effect = "Allow"
    actions = [
      "events:PutEvents",
    ]
    resources = [
      each.value.arn
    ]

    principals {
      type        = "AWS"
      identifiers = [var.starchart.aws_account_id]
    }
  }
}

resource "aws_cloudwatch_event_bus_policy" "eventbridge_resource_policy" {
  for_each = aws_cloudwatch_event_bus.bus

  policy         = data.aws_iam_policy_document.eventbridge_resource_policy[each.key].json
  event_bus_name = each.value.name
}

output "eventbridge" {
  value = {
    for k, v in aws_cloudwatch_event_bus.bus : k => {
      arn = v.arn
      id  = v.id
    }
  }
}
