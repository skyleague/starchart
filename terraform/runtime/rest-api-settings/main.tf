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

variable "authorizers" {
  type = map(object({
    identity_source = optional(list(string), [
      "context.httpMethod",
      "context.path",
      "method.request.header.Authorization",
    ])
    function_id    = optional(string)
    function_name  = optional(string)
    ttl_in_seconds = optional(number, 60)
    type           = optional(string, "request")
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

output "authorizers" {
  value       = var.authorizers
  description = "Map of authorizers for the API"
}

output "default_authorizer" {
  value       = var.default_authorizer
  description = "The default authorizer for the API"
}