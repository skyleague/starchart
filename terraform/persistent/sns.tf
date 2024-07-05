variable "sns_topic" {
  type = map(
    object({
      name_prefix = string
    })
  )
  default  = {}
  nullable = false
}

resource "aws_sns_topic" "sns_topic" {
  for_each = var.sns_topic

  name_prefix       = each.value.name_prefix
  kms_master_key_id = var.starchart.bootstrap.eventing_kms_key_arn
}

output "sns_topic" {
  value = {
    for topic_id, definition in aws_sns_topic.sns_topic : topic_id => {
      arn = definition.arn
    }
  }
}
