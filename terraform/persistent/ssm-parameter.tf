variable "secret" {
  type = map(
    object({
      name = string
    })
  )
  default  = {}
  nullable = false
}

resource "aws_secretsmanager_secret" "secret" {
  for_each = var.secret

  name = each.value.name
}

output "secret" {
  value = {
    for secret, definition in aws_secretsmanager_secret.secret : secret => {
      arn = definition.arn
    }
  }
}
