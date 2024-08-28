variable "template_variables" {
  type        = map(string)
  description = "The variables to be used when rendering the handler definition."
  default     = {}
}

variable "inline_policies" {
  type        = map(object({ json = string }))
  description = "The inline policies to be attached to the functions."
  default     = {}
}
