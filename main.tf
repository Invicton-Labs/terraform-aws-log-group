terraform {
  // Enable the optional attributes experiment
  experiments = [module_variable_optional_attrs]
}

// Create the logs group
resource "aws_cloudwatch_log_group" "loggroup" {
  name              = var.log_group_config.name
  name_prefix       = var.log_group_config.name_prefix
  retention_in_days = var.log_group_config.retention_in_days
  kms_key_id        = var.log_group_config.kms_key_id
  tags              = var.log_group_config.tags
}

// Prepare a policy document that allows logging to this log group
data "aws_iam_policy_document" "logging" {
  statement {
    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    resources = [
      aws_cloudwatch_log_group.loggroup.arn,
      "${aws_cloudwatch_log_group.loggroup.arn}:*"
    ]
  }
}

resource "aws_cloudwatch_log_subscription_filter" "subscription" {
  count           = length(var.subscriptions)
  name            = var.subscriptions[count.index].name != null ? var.subscriptions[count.index].arn : "Lambda Subscription"
  log_group_name  = aws_cloudwatch_log_group.loggroup.name
  filter_pattern  = var.subscriptions[count.index].filter != null ? var.subscriptions[count.index].filter : ""
  destination_arn = var.subscriptions[count.index].arn
}

resource "aws_lambda_permission" "allow_cloudwatch" {
  count         = length(var.subscriptions)
  action        = "lambda:InvokeFunction"
  function_name = var.subscriptions[count.index].arn
  principal     = "logs.amazonaws.com"
  source_arn    = aws_cloudwatch_log_group.loggroup.arn
}
