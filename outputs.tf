output "log_group" {
  description = "The `aws_cloudwatch_log_group` resource."
  value       = aws_cloudwatch_log_group.loggroup
}

output "logging_policy_json" {
  description = "The JSON representation of an IAM policy that allows writing logs to this Log Group."
  value       = data.aws_iam_policy_document.logging.json
}

output "complete" {
  description = "A flag for determining when everything in this module has been created."
  depends_on = [
    aws_cloudwatch_log_group.loggroup,
    aws_cloudwatch_log_subscription_filter.subscription,
    aws_lambda_permission.allow_cloudwatch
  ]
  value = true
}
