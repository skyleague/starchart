variable "attach_api_gateway_cloudwatch_role" {
  type        = bool
  default     = true
  nullable    = false
  description = "Attach the API Gateway CloudWatch role to the account, only needs to happen once per account"
}

data "aws_iam_policy_document" "apigateway_cloudwatch_role_assume_role" {
  count = var.attach_api_gateway_cloudwatch_role ? 1 : 0

  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["apigateway.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "apigateway_cloudwatch_role" {
  count = var.attach_api_gateway_cloudwatch_role ? 1 : 0

  name_prefix        = "api-gateway-cloudwatch-global"
  assume_role_policy = data.aws_iam_policy_document.apigateway_cloudwatch_role_assume_role[0].json
}

resource "aws_iam_role_policy_attachment" "apigateway_logging" {
  count = var.attach_api_gateway_cloudwatch_role ? 1 : 0

  role       = aws_iam_role.apigateway_cloudwatch_role[0].id
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonAPIGatewayPushToCloudWatchLogs"
}

resource "aws_api_gateway_account" "apigateway_account" {
  count = var.attach_api_gateway_cloudwatch_role ? 1 : 0

  cloudwatch_role_arn = aws_iam_role.apigateway_cloudwatch_role[0].arn

  lifecycle {
    ignore_changes = [cloudwatch_role_arn]
  }
}
