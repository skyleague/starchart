resource "aws_cloudwatch_event_rule" "eb_sqs" {
  for_each = var.eventbridge_to_sqs

  name_prefix    = each.key
  event_bus_name = each.value.event_bus_name
  event_pattern  = each.value.event_pattern
}

resource "aws_cloudwatch_event_target" "eb_sqs" {
  for_each = aws_cloudwatch_event_rule.eb_sqs

  event_bus_name = each.value.event_bus_name
  rule           = each.value.name
  target_id      = "SQS"
  arn            = var.sqs[each.key].queue.arn
}

data "aws_iam_policy_document" "eb_sqs" {
  for_each = aws_cloudwatch_event_rule.eb_sqs
  statement {
    effect    = "Allow"
    actions   = ["sqs:SendMessage"]
    resources = [var.sqs[each.key].queue.arn]
    principals {
      type        = "Service"
      identifiers = ["events.amazonaws.com"]
    }
    condition {
      test     = "ArnEquals"
      variable = "aws:SourceArn"
      values   = [each.value.arn]
    }
  }
}
resource "aws_sqs_queue_policy" "eb_sqs" {
  for_each = data.aws_iam_policy_document.eb_sqs

  queue_url = var.sqs[each.key].queue.url
  policy    = each.value.json
}
