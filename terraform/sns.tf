// SNS topic for global notifications (pipeline, alarms)
resource "aws_sns_topic" "notifications" {
  # SNS topic used for pipeline and alarm notifications
  name              = "${var.tags.product}-${var.tags.service}-notifications"
  display_name      = "Cloud Pipeline Notifications"
  kms_master_key_id = aws_kms_key.cloud.arn
  tags              = var.tags
}

// SNS topic subscription for email notifications (group mail)
resource "aws_sns_topic_subscription" "email" {
  # Subscribes an email endpoint to the notifications topic
  topic_arn = aws_sns_topic.notifications.arn
  protocol  = "email"
  endpoint  = var.email_alert
}
