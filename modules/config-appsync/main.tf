

locals {
  _datasource_names = toset(
    concat(
      [for item in local._resolver_config : item.datasource_id],
      [for item in local._function_config : item.datasource_id]
    )
  )
  _base_resolver_config = [
    for f in fileset(var.resolver_dir, "*/resolvers/*/${var.resolver_file}") : {
      field         = "${lower(element(split("-", basename(dirname(f))), 0))}${join("", [for s in slice(split("-", basename(dirname(f))), 1, length(split("-", basename(dirname(f))))) : "${upper(substr(s, 0, 1))}${substr(s, 1, -1)}"])}"
      datasource_id = basename(dirname(dirname(dirname(f))))
      field_dir     = basename(dirname(f))
      definition = yamldecode(
        templatefile(
          "${var.resolver_dir}/${f}",
          var.template_variables
        )
      )
    }
  ]
  _resolver_config = [
    for h in local._base_resolver_config : {
      definition    = h.definition
      field_dir     = h.field_dir
      field         = try(h.definition.field, replace(h.field, "/[^a-zA-Z0-9]+/", ""))
      resolver_id   = try(h.definition.resolverId, replace(h.field, "/[^a-zA-Z0-9]+/", "-"))
      datasource_id = try(h.definition.datasourceId, h.datasource_id)
    }
  ]
  _resolver_grouped_by_datasource = merge(
    { for datasource_id in local._datasource_names : datasource_id => {} },
    { for item in local._resolver_config : item.datasource_id => item... }
  )
  resolver_config = {
    for ds_id, items in local._resolver_grouped_by_datasource : ds_id => {
      for h in items : h.field => merge(h.definition, {
        field        = h.field
        resolver_id  = h.resolver_id
        artifact_dir = "${h.datasource_id}/${h.field_dir}"
  }) } }

  _base_function_config = [
    for f in fileset(var.function_dir, "*/functions/*/${var.function_file}") : {
      datasource_id = basename(dirname(dirname(dirname(f))))
      function_id   = basename(dirname(f))
      definition = yamldecode(
        templatefile(
          "${var.function_dir}/${f}",
          var.template_variables
        )
      )
    }
  ]
  _function_config = [
    for h in local._base_function_config : {
      definition    = h.definition
      function_id   = h.function_id
      function_id   = try(h.definition.functionId, replace(h.function_id, "/[^a-zA-Z0-9]+/", "-"))
      datasource_id = try(h.definition.datasourceId, h.datasource_id)
    }
  ]
  _function_grouped_by_datasource = merge(
    { for datasource_id in local._datasource_names : datasource_id => {} },
    { for item in local._function_config : item.datasource_id => item... }
  )
  function_config = { for ds_id, items in local._function_grouped_by_datasource : ds_id =>
    { for h in items : h.function_id => merge(h.definition, {
      function_id  = h.function_id
      artifact_dir = "${h.datasource_id}/${h.function_id}"
  }) } }
}
