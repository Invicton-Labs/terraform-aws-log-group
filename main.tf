terraform {
  required_version = ">= 1.0.0"
  experiments      = [module_variable_optional_attrs]
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
resource "aws_cloudwatch_log_subscription_filter" "subscription" {
  count = length(var.subscriptions)
  // Wait for proper permissions to be granted for Lambda subscriptions before creating the subscriptions themselves
  depends_on = [
    aws_lambda_permission.allow_cloudwatch
  ]
  name            = var.subscriptions[count.index].name
  log_group_name  = aws_cloudwatch_log_group.loggroup.name
  filter_pattern  = var.subscriptions[count.index].filter != null ? var.subscriptions[count.index].filter : ""
  destination_arn = var.subscriptions[count.index].arn
  role_arn        = var.subscriptions[count.index].role_arn
  distribution    = var.subscriptions[count.index].distribution
}

// Parse the subscription ARNs
data "aws_arn" "subscription_arns" {
  count = length(var.subscriptions)
  arn   = var.subscriptions[count.index].arn
}

locals {
  // Filter for Lambda subscriptions
  lambda_subscriptions = length(data.aws_arn.subscription_arns) > 0 ? [
    for i, v in var.subscriptions :
    v
    if lower(data.aws_arn.subscription_arns[i].service) == "lambda"
  ] : []
}

// For each Lambda subscription, create a Lambda permission
resource "aws_lambda_permission" "allow_cloudwatch" {
  for_each      = toset(local.lambda_subscriptions)
  action        = "lambda:InvokeFunction"
  function_name = each.value.arn
  principal     = "logs.amazonaws.com"
  source_arn    = aws_cloudwatch_log_group.loggroup.arn
}
