# provisions alerts for unsuccessful glue jobs
resource "aws_sns_topic" "glue_alerts" {
  name = "${local.name}-glue-alerts"
}

resource "aws_sns_topic_subscription" "glue_alerts_email" {
  topic_arn = aws_sns_topic.glue_alerts.arn
  protocol  = "email"
  endpoint  = var.alert_email
}

resource "aws_cloudwatch_event_rule" "glue_job_failed" {
  name        = "${local.name}-glue-job-failed"
  description = "Alert on ${local.name} Glue job failures/timeouts/stops"

  event_pattern = jsonencode({
    source        = ["aws.glue"]
    "detail-type" = ["Glue Job State Change"]
    detail = {
      state = ["FAILED", "TIMEOUT", "STOPPED"]
      jobName = [
        aws_glue_job.raw_to_curated.name,
        aws_glue_job.curated_to_rds.name
      ]
    }
  })
}

resource "aws_cloudwatch_event_target" "glue_job_failed_to_sns" {
  rule      = aws_cloudwatch_event_rule.glue_job_failed.name
  target_id = "SendToSNS"
  arn       = aws_sns_topic.glue_alerts.arn
}

data "aws_iam_policy_document" "sns_allow_eventbridge_publish" {
  statement {
    sid     = "AllowEventBridgePublish"
    effect  = "Allow"
    actions = ["sns:Publish"]

    principals {
      type        = "Service"
      identifiers = ["events.amazonaws.com"]
    }

    resources = [aws_sns_topic.glue_alerts.arn]

    condition {
      test     = "ArnEquals"
      variable = "aws:SourceArn"
      values   = [aws_cloudwatch_event_rule.glue_job_failed.arn]
    }
  }
}

resource "aws_sns_topic_policy" "glue_alerts_policy" {
  arn    = aws_sns_topic.glue_alerts.arn
  policy = data.aws_iam_policy_document.sns_allow_eventbridge_publish.json
}
