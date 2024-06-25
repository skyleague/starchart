locals {
  _datasources_flatten = {
    for datasource_id, resolvers in local.resolver_config : datasource_id => [
      for resolver_id, definition in resolvers : definition
    ]
  }
  # @todo: remove this
  datasource_to_type = {
    for datasource_id, resolvers in local.resolver_config : datasource_id =>
    try(var.resources.dynamodb[datasource_id], null) != null ? "dynamodb" : "none"
  }
  datasource_resource = {
    dynamodb = {
      for datasource_id, actions in local._datasources_flatten : datasource_id => {
        arn     = var.resources.dynamodb[datasource_id].arn
        actions = toset(flatten([for action in actions : action.actions]))
      }
      if try(var.resources.dynamodb[datasource_id], null) != null
    }
  }
}

data "aws_iam_policy_document" "dynamodb_access" {
  for_each = try(local.datasource_resource.dynamodb, {})

  statement {
    effect = "Allow"

    actions = toset(concat(
      anytrue([for action in ["read", "get"] : contains(each.value.actions, action)]) ? [
        "dynamodb:GetItem",
      ] : [],
      anytrue([for action in ["read", "query"] : contains(each.value.actions, action)]) ? [
        "dynamodb:Query",
      ] : [],
      anytrue([for action in ["write", "put"] : contains(each.value.actions, action)]) ? [
        "dynamodb:PutItem",
      ] : [],
      anytrue([for action in ["write", "update"] : contains(each.value.actions, action)]) ? [
        "dynamodb:UpdateItem",
      ] : [],
      contains(each.value.actions, "delete") ? [
        "dynamodb:DeleteItem",
      ] : [],
      contains(each.value.actions, "scan") ? [
        "dynamodb:Scan",
      ] : [],
    ))

    resources = [each.value.arn]
  }
}

output "policy" {
  value = {
    dynamodb = data.aws_iam_policy_document.dynamodb_access
  }
}

# resource "null_resource" "policy_validation" {
#   for_each = toset(flatten([
#     for function_id, definition in local.resolver_configs : try(definition.inlinePolicies, [])
#   ]))

#   triggers = {
#     policy_ids      = jsonencode(each.value)
#     inline_policies = jsonencode(var.inline_policies)
#   }

#   lifecycle {
#     precondition {
#       condition     = try(var.inline_policies[each.key], null) != null
#       error_message = "The inline policy '${each.key}' is not defined."
#     }
#   }
# }
