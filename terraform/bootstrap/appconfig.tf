resource "aws_appconfig_application" "application" {
  name        = local.config.project_name
  description = "Configuration application for ${local.config.project_name}"
}

output "appconfig" {
  value = {
    application = {
      id  = aws_appconfig_application.application.id
      arn = aws_appconfig_application.application.arn
    }
  }
}
