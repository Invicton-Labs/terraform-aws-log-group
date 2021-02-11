variable "log_group_config" {
  description = "The Log Group configuration. The arguments are the same as the `aws_cloudwatch_log_group` resource."
  type = object({
    name              = optional(string)
    name_prefix       = optional(string)
    retention_in_days = optional(number)
    kms_key_id        = optional(string)
    tags              = optional(map(string))
  })
}

variable "subscriptions" {
  description = "A list of configurations for Lambda subscriptions to the this Log Group. Each element should be a map with `arn` (required), `name` (optional), and `filter` (optional)."
  type = list(object({
    arn    = string
    name   = optional(string)
    filter = optional(string)
  }))
  default = []
}
