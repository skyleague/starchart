variable "resolver_dir" {
  type        = string
  description = "The directory containing the functions to be deployed."
}

variable "resolver_file" {
  type        = string
  description = "The name of the file containing the handler definition."
  default     = "resolver.yml"
}

variable "function_dir" {
  type        = string
  description = "The directory containing the functions to be deployed."
}

variable "function_file" {
  type        = string
  description = "The name of the file containing the handler definition."
  default     = "function.yml"
}

variable "template_variables" {
  type        = any
  description = "The variables to be used when rendering the handler definition."
  default     = {}
}

variable "resources" {
  type = object({
    secrets        = optional(map(object({ arn = string })), {})
    ssm_parameters = optional(map(object({ arn = string })), {})
    s3             = optional(map(object({ arn = string, id = string })), {})
    dynamodb       = optional(map(object({ arn = string, id = string })), {})
  })
  default = {}

  description = "The resources that can possibly be used by the functions."
}

variable "path_prefix" {
  type        = string
  description = "The path prefix to the resolvers."
}
