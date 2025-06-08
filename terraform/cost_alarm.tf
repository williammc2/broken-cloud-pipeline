// CloudWatch alarm for daily AWS cost > $1, notifies via SNS

resource "aws_cloudwatch_metric_alarm" "daily_cost" {
  alarm_name          = "${var.tags.product}-daily-cost-exceeded"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "EstimatedCharges"
  namespace           = "AWS/Billing"
  period              = 86400 // 1 day
  statistic           = "Maximum"
  threshold           = 1
  alarm_description   = "Alarm when daily AWS cost exceeds $1."
  actions_enabled     = true
  alarm_actions       = [aws_sns_topic.notifications.arn]
  tags                = var.tags
  dimensions = {
    Currency = "USD"
  }
}
