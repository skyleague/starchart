
variable "eventing_kms_key_arn" {
  type        = string
  nullable    = false
  default     = ""
  description = "The ID of the KMS key to use for encrypting the runtime events."
}

data "aws_iam_policy_document" "eventing_kms_key" {
  count = length(var.eventing_kms_key_arn) == 0 ? 1 : 0
  statement {
    sid       = "Enable IAM User Permissions"
    effect    = "Allow"
    actions   = ["kms:*"]
    resources = ["*"]

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${var.starchart.aws_account_id}:root"]
    }
  }

  statement {
    sid    = "Allow use of the key"
    effect = "Allow"
    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:DescribeKey"
    ]
    resources = ["*"]

    principals {
      type = "Service"
      identifiers = [
        "events.amazonaws.com",
        "sqs.amazonaws.com",
        "sns.amazonaws.com"
      ]
    }

    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [var.starchart.aws_account_id]
    }
  }

  statement {
    sid    = "Allow attachment of persistent resources"
    effect = "Allow"
    actions = [
      "kms:CreateGrant",
      "kms:ListGrants",
      "kms:RevokeGrant"
    ]
    resources = ["*"]

    principals {
      type = "Service"
      identifiers = [
        "events.amazonaws.com",
        "sqs.amazonaws.com",
        "sns.amazonaws.com"
      ]
    }

    condition {
      test     = "Bool"
      variable = "kms:GrantIsForAWSResource"
      values   = ["true"]
    }
  }
}

resource "aws_kms_key" "eventing_kms_key" {
  count = length(var.eventing_kms_key_arn) == 0 ? 1 : 0

  description             = "KMS key for encrypting all runtime eventing data"
  deletion_window_in_days = 30
  enable_key_rotation     = true
  policy                  = data.aws_iam_policy_document.eventing_kms_key[0].json
}

resource "aws_kms_alias" "eventing_kms_key" {
  count = length(var.eventing_kms_key_arn) == 0 ? 1 : 0

  name_prefix   = "alias/${local.config.project_name}/eventing"
  target_key_id = aws_kms_key.eventing_kms_key[0].key_id
}

output "eventing_kms_key_arn" {
  value = length(var.eventing_kms_key_arn) == 0 ? aws_kms_key.eventing_kms_key[0].arn : var.eventing_kms_key_arn
}
