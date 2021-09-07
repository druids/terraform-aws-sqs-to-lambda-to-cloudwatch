resource "aws_sqs_queue" "queue_dlq" {
  name       = "queue.fifo"
  fifo_queue = true

  deduplication_scope   = "messageGroup"
  fifo_throughput_limit = "perMessageGroupId"

  kms_master_key_id = "alias/aws/sqs"
}

module "lambda" {
  source = "../"

  resources_name = "lambda-sqs"
  sqs_queue_arn  = aws_sqs_queue.queue_dlq.arn
}
