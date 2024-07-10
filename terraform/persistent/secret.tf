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

data "aws_secretsmanager_secret" "secret" {
  for_each = {
    for secret_id, definition in var.resources.secret : secret_id => definition.name
    if definition.name != null && definition.arn == null
  }
  name = each.value.name
}

output "secret" {
  value = merge({
    for secret, definition in aws_secretsmanager_secret.secret : secret => {
      arn = definition.arn
    }
    },
    {
      for secret, definition in data.aws_secretsmanager_secret.secret : secret => {
        arn = definition.arn
      }
    },
    {
      for secret_id, definition in var.resources.secret : secret_id => {
        arn = definition.arn
      } if definition.arn != null
    },
  )
}
