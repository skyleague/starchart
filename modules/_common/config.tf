variable "config" {
  type = object({
    project_name       = string
    project_identifier = string
    environment        = string
    stack              = string
    domain             = string
    repo_root          = string
  })
  description = "The configuration for the project"
  nullable    = false
}

module "config" {
  source = "../_config"

  project_name       = var.config.project_name
  project_identifier = var.config.project_identifier
  environment        = var.config.environment
  stack              = var.config.stack
  domain             = var.config.domain
  repo_root          = var.config.repo_root
}

output "config" {
  value = module.config
}
