variable "sns_topic" {
  type = map(
    object({
      name = string
    })
  )
  default  = {}
  nullable = false
}

resource "aws_sns_topic" "sns_topic" {
  for_each = var.sns_topic

  name_prefix       = each.value.name
  kms_master_key_id = var.starchart.bootstrap.eventing_kms_key_arn
}

output "sns_topic" {
  value = {
    for secret, definition in aws_sns_topic.sns_topic : secret => {
      arn = definition.arn
    }
  }
}
