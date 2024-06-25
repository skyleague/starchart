resource "aws_appconfig_application" "application" {
  name        = local.config.project_name
  description = "Configuration application for ${local.config.project_name}"
}

output "appconfig_application_id" {
  value = aws_appconfig_application.application.id
}

output "appconfig_application_arn" {
  value = aws_appconfig_application.application.arn
}
