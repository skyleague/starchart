variable "s3" {
  type = map(
    object({
      name_prefix     = string
      lifecycle_rules = optional(any, [])
    })
  )
  default  = {}
  nullable = false
}

module "s3" {
  for_each = var.s3
  source   = "git::https://github.com/skyleague/aws-s3.git?ref=v1.1.0"

  bucket_name_prefix = each.value.name_prefix
  lifecycle_rules    = each.value.lifecycle_rules
}


output "s3" {
  value = {
    for id, definition in module.s3 : id => {
      arn = definition.this.arn
      id  = definition.this.id
    }
  }
}
