variable "starchart" {
  type = object({
    aws_account_id = string
    aws_region     = string
    config         = any
  })
}
