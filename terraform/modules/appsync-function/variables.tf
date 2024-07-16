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

variable "function" {
  type = map(object({
    # datasource_id = string
    # artifact_dir   = string
    # function_id    = string

    max_batch_size = optional(number)
    name           = optional(string)
    description    = optional(string)
    # sync_config     = optional(any)

    runtime = optional(object({
      name            = string
      runtime_version = string
    }))
  }))
  description = "The AppSync functions to be attached to datasources. Keys are the datasource IDs."
}

variable "function_code" {
  type        = map(string)
  sensitive   = true
  description = "The code to be executed by the function."
}

variable "api_id" {
  type        = string
  description = "The AppSync API ID."
}
