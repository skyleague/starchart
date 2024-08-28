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
      "$context.httpMethod",
      "$context.path",
      "$request.header.Authorization",
    ])
    ttl_in_seconds = optional(number, 60)

    # request
    function_id             = optional(string)
    function_name           = optional(string)
    enable_simple_responses = optional(bool, false)
    payload_format_version  = optional(string, "2.0")

    lambda = object({
      function_name = string
    })
  }))
  description = "Map of authorizers for the API"
  default     = {}
  nullable    = false
}

variable "jwt_authorizers" {
  type = map(object({
    type            = string
    security_scheme = optional(any)
    identity_source = optional(string, "$request.header.Authorization")
    ttl_in_seconds  = optional(number, 60)
    # jwt
    issuer   = optional(string)
    audience = optional(list(string))
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
    for name, authorizer in var.request_authorizers : name => {
      authorizerType                 = authorizer.type
      identitySource                 = join(",", authorizer.identity_source)
      resultTtlInSeconds             = authorizer.ttl_in_seconds
      authorizerPayloadFormatVersion = authorizer.payload_format_version
      enableSimpleResponses          = authorizer.enable_simple_responses
      lambda                         = authorizer.lambda
      # not sure if this is needed
      # header = authorizer.header
      securityScheme = authorizer.security_scheme
    }
  }
  description = "Map of authorizers for the API"
}

output "jwt_authorizers" {
  value = {
    for name, authorizer in var.jwt_authorizers : name => {
      authorizerType     = authorizer.type
      identitySource     = authorizer.identity_source
      resultTtlInSeconds = authorizer.ttl_in_seconds

      issuer   = authorizer.issuer
      audience = authorizer.audience
      
      securityScheme = authorizer.security_scheme
    }
  }
  description = "Map of authorizers for the API"
}

output "default_authorizer" {
  value       = var.default_authorizer
  description = "The default authorizer for the API"
}