variable "cloudwatch_retention_days" {
  default = 90
  type    = number
}

variable "resources_name" {
  type = string
}

variable "sqs_queue_arn" {
  description = "ARN of the SQS queue to read from"
  type        = string
}
