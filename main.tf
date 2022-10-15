terraform {
  required_version = ">= 1.3"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 3.38"
    }
  }
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

// Create each subscription filter
resource "aws_cloudwatch_log_subscription_filter" "lambda_subscriptions" {
  count = length(var.lambda_subscriptions)
  // Wait for proper permissions to be granted for Lambda subscriptions before creating the subscriptions themselves
  depends_on = [
    aws_lambda_permission.allow_cloudwatch
  ]
  name            = var.lambda_subscriptions[count.index].name
  log_group_name  = aws_cloudwatch_log_group.loggroup.name
  filter_pattern  = var.lambda_subscriptions[count.index].filter_pattern != null ? var.lambda_subscriptions[count.index].filter_pattern : ""
  destination_arn = var.lambda_subscriptions[count.index].destination_arn
  distribution    = var.lambda_subscriptions[count.index].distribution
}

// Create each subscription filter
resource "aws_cloudwatch_log_subscription_filter" "non_lambda_subscriptions" {
  count = length(var.non_lambda_subscriptions)
  // Wait for proper permissions to be granted for Lambda subscriptions before creating the subscriptions themselves
  depends_on = [
    aws_lambda_permission.allow_cloudwatch
  ]
  name            = var.non_lambda_subscriptions[count.index].name
  log_group_name  = aws_cloudwatch_log_group.loggroup.name
  filter_pattern  = var.non_lambda_subscriptions[count.index].filter_pattern != null ? var.non_lambda_subscriptions[count.index].filter_pattern : ""
  destination_arn = var.non_lambda_subscriptions[count.index].destination_arn
  role_arn        = var.non_lambda_subscriptions[count.index].role_arn
  distribution    = var.non_lambda_subscriptions[count.index].distribution
}

// For each Lambda subscription, create a Lambda permission
resource "aws_lambda_permission" "allow_cloudwatch" {
  count         = length(var.lambda_subscriptions)
  action        = "lambda:InvokeFunction"
  function_name = var.lambda_subscriptions[count.index].destination_arn
  principal     = "logs.amazonaws.com"
  source_arn    = aws_cloudwatch_log_group.loggroup.arn
}
