variable "functions_dir" {
  type        = string
  description = "The directory containing the functions to be deployed."
}

variable "handler_file" {
  type        = string
  description = "The name of the file containing the handler definition."
  default     = "handler.yml"
}

variable "eventbridge_kms_key_id" {
  type        = string
  description = "The ID of the KMS key to use for encrypting the EventBridge events."
}
