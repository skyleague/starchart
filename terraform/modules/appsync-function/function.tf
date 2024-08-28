resource "aws_appsync_function" "function" {
  for_each    = var.function
  data_source = var.datasource
  api_id      = var.api_id

  max_batch_size = each.value.max_batch_size
  name           = each.value.name
  description    = each.value.description
  code           = var.function_code[each.key]

  dynamic "runtime" {
    for_each = each.value.runtime != null ? [each.value.runtime] : []
    content {
      name            = runtime.value.name
      runtime_version = runtime.value.runtime_version
    }
  }
}

output "function" {
  value = aws_appsync_function.function
}
