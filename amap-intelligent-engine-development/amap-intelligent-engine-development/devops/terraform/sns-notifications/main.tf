
resource "aws_sns_topic" "this" {
  count = var.create_sns ? 1 : 0

  name                        = var.sns_topic_name
  kms_master_key_id           = var.kms_master_key_id
  delivery_policy             = var.delivery_policy
  fifo_topic                  = var.fifo_topic
  content_based_deduplication = var.content_based_deduplication

}

resource "aws_sns_topic_policy" "this" {
  count  = var.create_sns ? 1 : 0
  arn    = join("", aws_sns_topic.this.*.arn)
  policy = length(var.sns_topic_policy_json) > 0 ? var.sns_topic_policy_json : join("", data.aws_iam_policy_document.aws_sns_topic_policy.*.json)
}

data "aws_iam_policy_document" "aws_sns_topic_policy" {

  policy_id = "SNSTopicsPub"
  statement {
    effect    = "Allow"
    actions   = ["sns:Publish"]
    resources = aws_sns_topic.this.*.arn
    
    condition {
        test     = "StringEquals"
        variable = "aws:SourceAccount"
        values   = [var.aws_account_id]
    }

    dynamic "principals" {
      for_each = length(var.allowed_aws_services_for_sns_published) > 0 ? ["_enable"] : []
      content {
        type        = "Service"
        identifiers = var.allowed_aws_services_for_sns_published
       
      }
    }
  

    # don't add the IAM ARNs unless specified
    dynamic "principals" {
      for_each = length(var.allowed_iam_arns_for_sns_publish) > 0 ? ["_enable"] : []
      content {
        type        = "AWS"
        identifiers = var.allowed_iam_arns_for_sns_publish
      }
    }
  }
}
