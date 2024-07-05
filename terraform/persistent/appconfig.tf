variable "appconfig" {
  type = object({
    configuration_profiles = map(
      object({
        jsonschema    = string
        name          = string
        initial_value = optional(map(any), {})
        description   = optional(string)
      })
    )
    environments = map(
      object({
        name        = string
        description = optional(string)
      })
    )
  })
  default = {
    configuration_profiles = {}
    environments           = {}
  }
  nullable = false
}

resource "aws_appconfig_configuration_profile" "profile" {
  for_each = var.appconfig.configuration_profiles

  application_id = local.bootstrap.appconfig.application.id
  description    = each.value.description
  name           = each.value.name
  location_uri   = "hosted"

  dynamic "validator" {
    for_each = each.value.jsonschema != null ? [each.value.jsonschema] : []
    content {
      type    = "JSON_SCHEMA"
      content = validator.value
    }
  }
}

resource "aws_appconfig_hosted_configuration_version" "initial" {
  for_each = { for k, v in var.appconfig.configuration_profiles : k => v if v.initial_value != null }

  application_id           = local.bootstrap.appconfig.application.id
  configuration_profile_id = aws_appconfig_configuration_profile.profile[each.key].configuration_profile_id
  description              = "This is the initial configuration provided by the Terraform configuration."
  content_type             = "application/json"

  content = jsonencode(each.value.initial_value)

  lifecycle {
    ignore_changes = [content, description]
  }
}

resource "aws_appconfig_environment" "profile" {
  for_each = { for k, v in var.appconfig.configuration_profiles : k => v if v.initial_value != null }

  name           = each.value.name
  application_id = local.bootstrap.appconfig.application.id
  description    = each.value.description
}

output "appconfig" {
  value = {
    configuration_profiles = {
      for k, v in aws_appconfig_configuration_profile.profile : k => {
        configuration_profile_id = v.configuration_profile_id
      }
    }
    environments = {
      for k, v in aws_appconfig_environment.profile : k => {
        environment_id = v.environment_id
      }
    }
  }
}
