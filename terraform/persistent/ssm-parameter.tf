variable "ssm_parameter" {
  type = map(
    object({
      name = string
      type = optional(string, "SecureString")
    })
  )
  default  = {}
  nullable = false
}

resource "aws_ssm_parameter" "ssm_parameter" {
  for_each = var.ssm_parameter

  name  = each.value
  type  = each.value.type
  value = ""

  lifecycle {
    ignore_changes = [value]
  }
}

output "ssm_parameter" {
  value = {
    for parameter_id, definition in aws_secretsmanager_secret.secret : parameter_id => {
      arn = definition.arn
    }
  }
}
