variable "functions_dir" {
  type        = string
  description = "The directory containing the functions to be deployed."
}

variable "handler_file" {
  type        = string
  description = "The name of the file containing the handler definition."
  default     = "handler.yml"
}

variable "template_variables" {
  type        = any
  description = "The variables to be used when rendering the handler definition."
  default     = {}
}

variable "function_prefix" {
  type        = string
  description = "The prefix to be used when naming the functions."
  default     = ""
}

variable "inline_policies" {
  type        = map(object({ json = string }))
  description = "The inline policies to be attached to the functions."
  default     = {}
}
