variable "s3" {
  type = map(
    object({
      name = string
    })
  )
  default  = {}
  nullable = false
}

module "s3" {
  for_each = var.s3
  source   = "git@github.com:skyleague/aws-s3.git?ref=v1.0.0"

  bucket_name_prefix = "${local.config.environment}-${local.config.stack_prefix}-${each.value.name}"
}


output "s3" {
  value = {
    for id, definition in module.s3 : id => {
      arn = definition.this.arn
      id  = definition.this.id
    }
  }
}
