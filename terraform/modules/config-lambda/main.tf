

locals {
  _base_handlers = [
    for f in fileset(var.functions_dir, "functions/*/${var.handler_file}") : {
      basedir      = dirname(f)
      handler_file = "${var.functions_dir}/${f}"
    }
  ]
  _handlers = [
    for h in local._base_handlers : {
      basedir      = h.basedir
      definition   = yamldecode(file(h.handler_file))
      function_id  = try(h.definition.functionId, replace(replace(h.basedir, "functions/", ""), "/[^a-zA-Z0-9]+/", "-"))
      handler_file = h.handler_file
    }
  ]
  handlers = {
    for h in local._handlers : h.function_id => merge(h.definition, {
      function_name = "${var.function_prefix}${try(h.definition.functionName, h.function_id)}"
      artifact_path = h.basedir
      handler_file  = h.handler_file
    })
  }
  formatted_handlers = {
    for fid, h in local.handlers : fid => merge(
      h,
      yamldecode(templatefile(h.handler_file, merge(var.template_variables, local.resources_env))),
      {
        function_name = h.function_name
        artifact_path = h.artifact_path
      }
    )
  }
}

