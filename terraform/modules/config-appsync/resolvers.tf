locals {
  datasource = {
    for datasource_id in local._datasource_names : datasource_id => {
      type = local.datasource_to_type[datasource_id]
      resolver = {
        for resolver_id, definition in local.resolver_config[datasource_id] : resolver_id => {
          datasource_id  = datasource_id
          artifact_dir   = definition.artifact_dir
          field          = definition.field
          type           = definition.type
          max_batch_size = try(definition.maxBatchSize, null)
          kind           = try(length(definition.pipeline) > 0 ? "PIPELINE" : "UNIT", definition.kind, null)

          # @todo
          # sync_config     = try(definition.syncConfig, null)
          pipeline_config = try(length(definition.pipeline) > 0 ? definition.pipeline : null, null)
          # caching_config  = try(definition.cachingConfig, null)

          runtime = {
            name            = "APPSYNC_JS"
            runtime_version = "1.0.0"
          }
        }
      }
      function = {
        for function_id, definition in try(local.function_config[datasource_id], {}) : function_id => {
          datasource_id = datasource_id
          artifact_dir  = definition.artifact_dir

          max_batch_size = try(definition.maxBatchSize, null)
          name           = coalesce(try(definition.name, null), function_id)
          description    = try(definition.description, null)

          # @todo
          # sync_config     = try(definition.syncConfig, null)
          runtime = {
            name            = "APPSYNC_JS"
            runtime_version = "1.0.0"
          }
        }
      }
    }
  }
  resolver_code = {
    for datasource_id, resolver in local.resolver_config : datasource_id => {
      for resolver_id, definition in resolver : resolver_id =>
      file("${var.path_prefix}/resolver/${definition.artifact_dir}/index.js")
    }
  }
  function_code = {
    for datasource_id, function in local.function_config : datasource_id => {
      for function_id, definition in function : function_id =>
      file("${var.path_prefix}/function/${definition.artifact_dir}/index.js")
    }
  }
}

output "datasource" {
  value = local.datasource
}

output "resolver_code" {
  value     = local.resolver_code
  sensitive = true
}
output "function_code" {
  value     = local.function_code
  sensitive = true
}
