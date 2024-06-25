resource "null_resource" "policy_validation" {
  for_each = toset(flatten([
    for function_id, definition in local.handlers : try(definition.inlinePolicies, [])
  ]))

  triggers = {
    policy_ids      = jsonencode(each.value)
    inline_policies = jsonencode(var.inline_policies)
  }

  lifecycle {
    precondition {
      condition     = try(var.inline_policies[each.key], null) != null
      error_message = "The inline policy '${each.key}' is not defined."
    }
  }
}
