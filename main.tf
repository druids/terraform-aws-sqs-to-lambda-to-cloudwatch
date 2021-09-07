terraform {
  required_providers {
    archive = {
      source  = "hashicorp/archive"
      version = "~> 2"
    }

    aws = {
      source  = "hashicorp/aws"
      version = "~> 3"
    }
  }
}

data "aws_iam_policy_document" "assume_lambda" {
  statement {
    actions = ["sts:AssumeRole"]
    effect  = "Allow"

    principals {
      identifiers = ["lambda.amazonaws.com"]
      type        = "Service"
    }
  }
}

resource "aws_iam_role" "lambda" {
  name = var.resources_name

  assume_role_policy = data.aws_iam_policy_document.assume_lambda.json
}

resource "aws_cloudwatch_log_group" "lambda" {
  name = "/aws/lambda/${var.resources_name}"

  retention_in_days = var.cloudwatch_retention_days
}

data "aws_iam_policy_document" "lambda" {
  statement {
    actions = [
      "sqs:DeleteMessage",
      "sqs:GetQueueAttributes",
      "sqs:ReceiveMessage",
    ]
    effect    = "Allow"
    resources = [var.sqs_queue_arn]
    sid       = "SQSTrigger"
  }
}

resource "aws_iam_policy" "lambda" {
  name = var.resources_name

  policy = data.aws_iam_policy_document.lambda.json
}

resource "aws_iam_role_policy_attachment" "lambda" {
  role       = aws_iam_role.lambda.name
  policy_arn = aws_iam_policy.lambda.arn
}

data "aws_iam_policy" "lambda_basic_execution_role" {
  arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy_attachment" "lambda_basic_execution_role" {
  role       = aws_iam_role.lambda.name
  policy_arn = data.aws_iam_policy.lambda_basic_execution_role.arn
}

locals {
  lambda_zip_path = "${path.module}/lambda.zip"
}

resource "aws_lambda_function" "lambda" {
  filename      = local.lambda_zip_path
  function_name = var.resources_name
  role          = aws_iam_role.lambda.arn
  handler       = "lambda.handler"

  source_code_hash = filebase64sha256(local.lambda_zip_path)

  runtime = "python3.9"

  depends_on = [
    aws_cloudwatch_log_group.lambda,
    aws_iam_role_policy_attachment.lambda,
  ]
}

resource "aws_lambda_event_source_mapping" "sqs_event" {
  event_source_arn = var.sqs_queue_arn
  function_name    = aws_lambda_function.lambda.arn

  enabled    = true
  batch_size = 10
}
