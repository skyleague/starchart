resource "aws_iam_role_policy" "this" {
  for_each = { for name, policy in var.policy : name => policy.json if policy != null }
  role     = var.role.id
  policy   = each.value
}
