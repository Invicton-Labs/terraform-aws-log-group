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
  description = "A list of configurations for Lambda subscriptions to the this Log Group. Each element should be a map with `destination_arn` (required), `name` (required), `filter_pattern` (optional), `role_arn` (optional), and `distribution` (optional)."
  type = list(object({
    destination_arn = string
    name            = string
    filter_pattern  = optional(string)
    role_arn        = optional(string)
    distribution    = optional(string)
  }))
  default = []
}
