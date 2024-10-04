variable "dynamodb" {
  type = map(
    object({
      name = string
      hash_key = object({
        name = string
        type = optional(string, "S")
      })
      range_key = optional(object({
        name = string
        type = optional(string, "S")
      }))
      global_secondary_indexes = optional(map(object({
        hash_key = object({
          name = string
          type = optional(string, "S")
        })
        range_key = optional(object({
          name = string
          type = optional(string, "S")
        }))
        projection_type    = optional(string, "KEYS_ONLY")
        non_key_attributes = optional(set(string))
        provisioned_capacity = optional(object({
          read  = number
          write = number
        }))
      })))
      deletion_protection_enabled = optional(bool, true)
    })
  )
  default  = {}
  nullable = false
}


module "dynamodb" {
  for_each = var.dynamodb
  source   = "git::https://github.com/skyleague/aws-dynamodb.git?ref=v3.0.0"

  name                   = each.value.name
  hash_key               = each.value.hash_key
  range_key              = coalesce(each.value.range_key, null)
  global_secondary_index = coalesce(each.value.global_secondary_index, null)

  deletion_protection_enabled = each.value.deletion_protection_enabled
}

output "dynamodb" {
  value = {
    for k, v in module.dynamodb : k => {
      arn = v.table.arn
      id  = v.table.id
    }
  }
}
