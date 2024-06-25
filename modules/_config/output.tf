output "project_name" {
  value = var.project_name
}

output "project_identifier" {
  value = var.project_identifier
}

output "environment" {
  value = var.environment
}

output "stack" {
  value = var.stack
}

output "domain" {
  value = var.domain
}

output "repo_root" {
  value = var.repo_root
}

output "stack_prefix" {
  value = var.stack
}

output "resource_prefix" {
  value = "${var.environment}-${var.project_identifier}-${var.stack}"
}
