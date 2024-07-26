variable "runtime" {
  type     = string
  nullable = false
}

variable "memory_size" {
  type     = number
  nullable = false
}

variable "timeout" {
  type     = number
  nullable = false
}

variable "handler" {
  type     = string
  nullable = false
  default  = "index.handler"
}

variable "functions_dir" {
  type     = string
  nullable = false
}

variable "function_prefix" {
  type     = string
  nullable = false
}

variable "handler_file" {
  type     = string
  nullable = false
  default  = "handler.yml"
}

variable "vpc_config" {
  type    = any
  default = null
}

variable "environment" {
  type     = map(string)
  default  = {}
  nullable = false
}

variable "inline_policies" {
  type     = map(object({ json = string }))
  default  = {}
  nullable = false
}

variable "local_artifact" {
  type = object({
    type        = optional(string, "zip")
    path_prefix = optional(string)
    s3_bucket   = optional(string)
    s3_prefix   = optional(string)
  })
  default  = {}
  nullable = true
}


output "runtime" {
  value = var.runtime
}

output "functions_dir" {
  value = var.functions_dir
}

output "function_prefix" {
  value = var.function_prefix
}

output "handler_file" {
  value = var.handler_file
}

output "memory_size" {
  value = var.memory_size
}

output "timeout" {
  value = var.timeout
}

output "handler" {
  value = var.handler
}

output "environment" {
  value = var.environment
}

output "inline_policies" {
  value = var.inline_policies
}

output "vpc_config" {
  value = var.vpc_config
}

output "local_artifact" {
  value = var.local_artifact
}