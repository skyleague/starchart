variable "functions_dir" {
  type        = string
  description = "The directory containing the functions to be deployed."
}

variable "handler_file" {
  type        = string
  description = "The name of the file containing the handler definition."
  default     = "handler.yml"
}

variable "function_prefix" {
  type        = string
  description = "The prefix to be used when naming the functions."
  default     = ""
}

locals {
  _base_handlers = [
    for f in fileset(var.functions_dir, "functions/*/${var.handler_file}") : {
      basedir      = dirname(f)
      handler_file = "${var.functions_dir}/${f}"
      definition = yamldecode(
        file("${var.functions_dir}/${f}")
      )
    }
  ]
  _handlers = [
    for h in local._base_handlers : {
      basedir      = h.basedir
      handler_file = h.handler_file
      definition   = h.definition
      function_id  = try(h.definition.functionId, replace(replace(h.basedir, "functions/", ""), "/[^a-zA-Z0-9]+/", "-"))
    }
  ]
  handlers = {
    for h in local._handlers : h.function_id => merge(h.definition, {
      function_name = "${var.function_prefix}${try(h.definition.functionName, h.function_id)}"
      artifact_path = h.basedir
      handler_file  = h.handler_file
    })
  }
}

output "handlers" {
  value = local.handlers
}
