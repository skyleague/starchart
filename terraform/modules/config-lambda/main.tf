

locals {
  handlers = var.handlers
  # formatted_handlers = yamldecode(
  #   templatestring(
  #     tostring(yamlencode(tomap(var.handlers))),
  #     merge(var.template_variables, local.resources_env)
  #   )
  # )

  formatted_handlers = {
    for k, v in var.handlers : k => merge(
      v,
      yamldecode(templatefile(v.handler_file, merge(var.template_variables, local.resources_env))),
      {
        function_name = v.function_name
        artifact_path = v.artifact_path
      }
    )
  }

  # handlers = {
  #   for k0, v0 in var.handlers : k0 => {
  #     for k1, v1 in v0 : k1 => jsondecode(
  #       templatestring(
  #         jsonencode(v1),
  #         merge(var.template_variables, local.resources_env)
  #       )
  #     )
  #   }
  # }
}

