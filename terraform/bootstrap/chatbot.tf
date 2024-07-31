variable "chatbot" {
  type = object({
    sns_topic_arns = optional(list(string), [])
		slack_channel_id = string
		slack_workspace_id = string
  })
  nullable    = true
  default     = null
  description = "Chatbot configuration."
}

locals {
  chatbot_enabled = var.chatbot != null && try(var.chatbot.slack_channel_id, null) != null && try(var.chatbot.slack_workspace_id, null) != null ? true : false
}

resource "aws_sns_topic" "chatbot_notification" {
  count             = local.chatbot_enabled ? 1 : 0

  name_prefix       = "${local.config.project_name}-chatbot-notification"
  kms_master_key_id = local.eventing_kms_key_arn
}

resource "awscc_chatbot_slack_channel_configuration" "chatbot" {
  count             = local.chatbot_enabled ? 1 : 0

  configuration_name = local.config.project_name
  iam_role_arn       = aws_iam_role.chatbot[0].arn
  slack_channel_id   = var.chatbot.slack_channel_id
  slack_workspace_id = var.chatbot.slack_workspace_id

  sns_topic_arns = concat([
    aws_sns_topic.chatbot_notification[0].arn,
  ], var.chatbot.sns_topic_arns)
  logging_level = "INFO"
  guardrail_policies = [
    "arn:aws:iam::aws:policy/ReadOnlyAccess"
  ]
}

resource "aws_iam_role" "chatbot" {
  count             = local.chatbot_enabled ? 1 : 0

  name_prefix = "${local.config.project_name}-chatbot"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "chatbot.amazonaws.com"
        }
      }
    ]
  })
  managed_policy_arns = ["arn:aws:iam::aws:policy/AWSIncidentManagerResolverAccess", "arn:aws:iam::aws:policy/CloudWatchReadOnlyAccess"]
}

output "chatbot" {
	value = local.chatbot_enabled ? {
		sns_notication_arn = aws_sns_topic.chatbot_notification[0].arn
	} : null
}