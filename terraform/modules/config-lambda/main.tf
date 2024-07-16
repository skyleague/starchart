

locals {
  _base_handlers = [
    for f in fileset(var.functions_dir, "functions/*/${var.handler_file}") : {
      basedir = dirname(f)
      definition = yamldecode(
        templatefile(
          "${var.functions_dir}/${f}",
          merge(var.template_variables, local.resources_env)
        )
      )
    }
  ]
  _handlers = [
    for h in local._base_handlers : {
      basedir     = h.basedir
      definition  = h.definition
      function_id = try(h.definition.functionId, replace(replace(h.basedir, "functions/", ""), "/[^a-zA-Z0-9]+/", "-"))
    }
  ]
  handlers = {
    for h in local._handlers : h.function_id => merge(h.definition, {
      function_name = "${var.function_prefix}${try(h.definition.functionName, h.function_id)}"
      artifact_path = h.basedir
    })
  }
}

