variable "starchart" {
  type = object({
    aws_account_id = string
    config         = any
  })
}
