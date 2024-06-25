variable "project_name" {
  type        = string
  description = "Name of the project, used for tagging and naming resources"
  nullable    = false

  validation {
    condition     = 0 < length(var.project_name) && length(var.project_name) <= 36
    error_message = "The project name must be non empty and smaller or equal to 36 characters."
  }

  validation {
    condition     = can(regex("^[0-9A-Za-z-]+$", var.project_name))
    error_message = "For the project name value only a-z, A-Z and 0-9, and - are allowed."
  }
}

variable "project_identifier" {
  type        = string
  description = "Short prefix of the project, used for tagging and naming resources"
  nullable    = false

  validation {
    condition     = 0 < length(var.project_identifier) && length(var.project_identifier) <= 6
    error_message = "The project prefix must be non empty and smaller or equal to 6 characters."
  }

  validation {
    condition     = can(regex("^[0-9A-Za-z]+$", var.project_identifier))
    error_message = "For the project prefix value only a-z, A-Z and 0-9 are allowed."
  }
}

variable "environment" {
  type        = string
  description = "value of the environment variable"
  nullable    = false

  validation {
    condition     = 0 < length(var.environment) && length(var.environment) <= 6
    error_message = "The project prefix must be non empty and smaller or equal to 6 characters."
  }

  validation {
    condition     = can(regex("^[0-9A-Za-z]+$", var.environment))
    error_message = "For the environment value only a-z, A-Z and 0-9 are allowed."
  }
}

variable "stack" {
  type        = string
  description = "Name of the stack used for logical separation of resources"
  nullable    = false

  validation {
    condition     = 0 < length(var.stack) && length(var.stack) <= 36
    error_message = "The stack name must be non empty and smaller or equal to 36 characters."
  }

  validation {
    condition     = can(regex("^[0-9A-Za-z-]+$", var.stack))
    error_message = "For the stack name value only a-z, A-Z and 0-9, and - are allowed."
  }
}

variable "domain" {
  type        = string
  description = "Domain of the project, used for tagging and naming resources"
  nullable    = false
}

variable "repo_root" {
  type        = string
  description = "Root of the repository"
  nullable    = false
}
