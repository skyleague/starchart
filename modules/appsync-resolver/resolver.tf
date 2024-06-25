resource "aws_appsync_resolver" "resolver" {
  for_each    = var.resolver
  data_source = each.value.pipeline_config != null ? null : var.datasource

  type           = each.value.type
  api_id         = var.api_id
  field          = each.value.field
  kind           = each.value.kind
  max_batch_size = each.value.max_batch_size
  code           = var.resolver_code[each.key]

  dynamic "pipeline_config" {
    for_each = each.value.pipeline_config != null ? [each.value.pipeline_config] : []
    content {
      functions = pipeline_config.value.functions
    }
  }

  dynamic "runtime" {
    for_each = each.value.runtime != null ? [each.value.runtime] : []
    content {
      name            = runtime.value.name
      runtime_version = runtime.value.runtime_version
    }
  }
}

output "resolver" {
  value = aws_appsync_resolver.resolver
}
