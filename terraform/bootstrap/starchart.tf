variable "starchart" {
  type = object({
    aws_account_id = string
    aws_region     = string
    config         = any
  })
}

locals {
  starchart = var.starchart
}