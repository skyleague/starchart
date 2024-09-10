module "common" {
  source = "../modules/_common"

  config       = local.starchart.config
  default_tags = local.starchart.default_tags
}

locals {
  config     = module.common.config
  bootstrap  = local.starchart.bootstrap
  persistent = local.starchart.persistent
}


# output "output" {
#   value = var.starchart
# }

output "cloudwatch_log_groups" {
  value = {
    lambda   = local._cloudwatch_lambda
    http_api = local._cloudwatch_http_api
    rest_api = local._cloudwatch_rest_api
  }
}
