variable "secrets" {
  type = map(
    object({})
  )
  default  = {}
  nullable = false
}

resource "aws_secretsmanager_secret" "secret" {
  for_each = var.secrets

  name = "/${local.config.stack_prefix}/${each.key}"
}

output "secrets" {
  value = {
    for secret, definition in aws_secretsmanager_secret.secret : secret => {
      arn = definition.arn
    }
  }
}
