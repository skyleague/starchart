variable "bootstrap" {
  type = object({
    application = optional(object({
      id = string
      arn = string
    }))
    artifacts_bucket_id = optional(string)
    chatbot = optional(object({
      sns_notication_arn = string
    }))
    eventing_kms_key_arn = optional(string)
  })
  description = "The bootstrap configuration output for the project"
  default     = null
  nullable    = true
}

variable "config" {
  type = object({
    project_name       = string
    project_identifier = string
    environment        = string
    stack_name         = string
    stack              = any
    repo_root          = string
    starchart          = any
  })
  description = "The configuration for the project"
  nullable    = false
}

module "config" {
  source = "../_config"

  project_name       = var.config.project_name
  project_identifier = var.config.project_identifier
  environment        = var.config.environment
  stack_name         = var.config.stack_name
  stack              = var.config.stack
  repo_root          = var.config.repo_root
  starchart          = var.config.starchart

  bootstrap = var.bootstrap
}

output "config" {
  value = module.config
}
