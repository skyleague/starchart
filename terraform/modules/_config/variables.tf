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

variable "stack_name" {
  type        = string
  description = "Name of the stack used for logical separation of resources"
  nullable    = false

  validation {
    condition     = 0 < length(var.stack_name) && length(var.stack_name) <= 36
    error_message = "The stack name must be non empty and smaller or equal to 36 characters."
  }

  validation {
    condition     = can(regex("^[0-9A-Za-z-]+$", var.stack_name))
    error_message = "For the stack name value only a-z, A-Z and 0-9, and - are allowed."
  }
}

variable "repo_root" {
  type        = string
  description = "Root of the repository"
  nullable    = false
}

variable "starchart" {
  type        = object({
    monitoring = optional(any)
  })
  description = "The starchart configuration as loaded from the starchart.yml file"
  nullable    = false
}

variable "stack" {
  type        = object({
    path = optional(string)
    httpApi = optional(object({
      name = optional(string)
      deferDeployment = optional(bool)
      disableExecuteApiEndpoint = optional(bool)
      defaultAuthorizer = optional(object({
        name = string
        scopes = optional(list(string))
      }))
      authorizers = optional(map(object({
        type = string
        identitySource = optional(list(string))
        ttlInSeconds = optional(number)
        functionId = optional(string)
        functionName = optional(string)
        issuer = optional(string)
        audience = optional(list(string))
        securityScheme = any
      })))
      monitoring = optional(any)
    }))
    restApi = optional(object({
      name = optional(string)
      deferDeployment = optional(bool)
      disableExecuteApiEndpoint = optional(bool)
      defaultAuthorizer = optional(object({
        name = string
        scopes = optional(list(string))
      }))
      authorizers = optional(map(object({
        type = string
        identitySource = optional(list(string))
        ttlInSeconds = optional(number)
        functionId = optional(string)
        functionName = optional(string)
        securityScheme = any
      })))
      monitoring = optional(any)
    }))

    lambda = optional(object({
      runtime = optional(string)
      memorySize = optional(number)
      timeout = optional(number)
      handler = optional(string)
      vpcConfig = optional(string)
      environment = optional(map(string))
      inlinePolicies = optional(any)
      functionsDir = optional(string)
      functionPrefix = optional(string)
      handlerFile = optional(string)
    }))
  })
  description = "The stack configuration as loaded from the stack.yml file"
  nullable    = true
}

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