variable "name" {
  type        = string
  description = "The name of the API Gateway"
  nullable    = false
}

variable "definition" {
  type        = any
  description = "The OpenAPI definition for the API"
  default     = {}
}

variable "defer_deployment" {
  type        = bool
  description = "Whether to defer deployment of the API"
  default     = false
  nullable    = false
}

variable "disable_execute_api_endpoint" {
  type        = bool
  description = "Whether to disable the execute-api endpoint"
  default     = true
  nullable    = false
}

variable "request_authorizers" {
  type = map(object({
    type = string
    security_scheme = optional(any)
    identity_source = optional(list(string), [
      "context.httpMethod",
      "context.path",
      "method.request.header.Authorization",
    ])
    ttl_in_seconds = optional(number, 60)

    function_id             = optional(string)
    function_name           = string
  }))
  description = "Map of authorizers for the API"
  default     = {}
  nullable    = false
}

variable "default_authorizer" {
  type        = object({
    name = string
    scopes = optional(list(string), [])
  })
  description = "The default authorizer for the API"
  default     = null
}

output "name" {
  value       = var.name
  description = "The name of the API Gateway"
}

output "definition" {
  value       = var.definition
  description = "The OpenAPI definition for the API"
}

output "defer_deployment" {
  value       = var.defer_deployment
  description = "Whether deployment of the API is deferred"
}

output "disable_execute_api_endpoint" {
  value       = var.disable_execute_api_endpoint
  description = "Whether the execute-api endpoint is disabled"
}

output "request_authorizers" {
  value = {
    for name, authorizer in var.request_authorizers : name => merge(authorizer, {
      identity_source = join(",", authorizer.identity_source)
    })
  }
  description = "Map of authorizers for the API"
}

output "default_authorizer" {
  value       = var.default_authorizer
  description = "The default authorizer for the API"
}