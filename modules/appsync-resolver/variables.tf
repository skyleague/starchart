variable "datasource" {
  type        = string
  description = "The AppSync datasource to attach the resolvers to."
}

variable "role" {
  type        = object({ id = string })
  description = "The IAM role to be attached to the datasources."
}

variable "policy" {
  type        = map(object({ json = string }))
  description = "The policies to be attached to the datasources."
}

variable "resolver" {
  type = map(object({
    # datasource_id = string
    # artifact_dir   = string
    field          = string
    type           = string
    max_batch_size = optional(number)
    kind           = optional(string)
    # sync_config     = optional(any)
    pipeline_config = optional(object({
      functions = list(string)
    }))
    # caching_config  = optional(any)
    runtime = optional(object({
      name            = string
      runtime_version = string
    }))
  }))
  description = "The AppSync resolvers to be attached to datasources. Keys are the datasource IDs."
}

variable "resolver_code" {
  type        = map(string)
  sensitive   = true
  description = "The code to be executed by the resolver."
}

variable "api_id" {
  type        = string
  description = "The AppSync API ID."
}
