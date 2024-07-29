# locals {
#   resolver_file = coalesce(var.appsync_config.resolver_file, "resolver.yml")
#   function_file = coalesce(var.appsync_config.function_file, "function.yml")
# }

# variable "appsync_config" {
#   type = object({
#     resolver_dir  = string
#     resolver_file = optional(string)
#     function_dir  = string
#     function_file = optional(string)
#   })
#   default = {
#     resolver_dir  = "../../../../src/graphql"
#     resolver_file = "resolver.yml"
#     function_dir  = "../../../../src/graphql"
#     function_file = "function.yml"
#   }
# }

# module "starchart_config_appsync" {
#   source = "../modules/config-appsync"

#   resolver_dir  = "${path.module}/../../../src/graphql" #var.appsync_config.resolver_dir
#   resolver_file = local.resolver_file

#   function_dir  = "${path.module}/../../../src/graphql" #var.appsync_config.function_dir
#   function_file = local.function_file

#   template_variables = {} #var.template_variables
#   path_prefix        = "${path.module}/../../../.artifacts"

#   resources = {
#     dynamodb = var.persistent.dynamodb
#   }
# }

# module "appsync" {
#   source = "../modules/main.starchart.graphql"

#   name        = var.project_name
#   name_prefix = var.project_identifier

#   authentication_type = "AWS_IAM"

#   datasources = {
#     dynamodb = {
#       # @TODO: how to handle overlap in datasource ids
#       data = {
#         table_name = var.persistent_state.dynamodb["data"].table.name
#       }
#     }
#     none = {
#       local = {}
#     }
#   }
# }

# module "appsync_runtime_unit" {
#   source = "../modules/main.starchart.appsync_runtime"

#   for_each = module.starchart_config_appsync.datasource

#   datasource    = module.appsync.datasource[each.value.type][each.key].datasource.name
#   role          = module.appsync.datasource[each.value.type][each.key].role
#   policy        = { default = try(module.starchart_config_appsync.policy[each.value.type][each.key], null) }
#   resolver      = { for resolver_id, resolver in each.value.resolver : resolver_id => resolver if resolver.pipeline_config == null }
#   function      = each.value.function
#   api_id        = module.appsync.graphql_api.id
#   resolver_code = try(module.starchart_config_appsync.resolver_code[each.key], {})
#   function_code = try(module.starchart_config_appsync.function_code[each.key], {})
# }

# module "appsync_runtime_pipeline" {
#   source = "../modules/main.starchart.appsync_runtime"

#   for_each = module.starchart_config_appsync.datasource

#   datasource = module.appsync.datasource[each.value.type][each.key].datasource.name
#   role       = module.appsync.datasource[each.value.type][each.key].role
#   policy     = {}
#   resolver = { for resolver_id, resolver in each.value.resolver : resolver_id =>
#     merge(resolver, {
#       pipeline_config = {
#         functions = [for pipeline in resolver.pipeline_config : module.appsync_runtime_unit[pipeline.datasource].function[pipeline.functionId].function_id]
#       }
#   }) if resolver.pipeline_config != null }
#   function      = {}
#   api_id        = module.appsync.graphql_api.id
#   resolver_code = try(module.starchart_config_appsync.resolver_code[each.key], {})
#   function_code = try(module.starchart_config_appsync.function_code[each.key], {})

#   depends_on = [module.appsync_runtime_unit]
# }
