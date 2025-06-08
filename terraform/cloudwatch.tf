// CloudWatch alarms and log groups for global monitoring


// CloudWatch log group for ECS application tasks
resource "aws_cloudwatch_log_group" "ecs_app" {
  // Stores logs for the main application ECS tasks
  name              = "/ecs/${var.tags.product}-app"
  retention_in_days = 365
  tags              = var.tags
  kms_key_id        = aws_kms_key.cloud.arn
}

// CloudWatch log group for ECS Jenkins tasks
resource "aws_cloudwatch_log_group" "ecs_jenkins" {
  // Stores logs for Jenkins ECS tasks
  name              = "/ecs/${var.tags.product}-jenkins"
  retention_in_days = 365
  tags              = var.tags
  kms_key_id        = aws_kms_key.cloud.arn
}

// CloudWatch alarm for ALB 5xx errors
resource "aws_cloudwatch_metric_alarm" "alb_5xx" {
  // Triggers an alarm if the Application Load Balancer returns any 5xx errors
  alarm_name          = "${var.tags.product}-alb-5xx-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "HTTPCode_ELB_5XX_Count"
  namespace           = "AWS/ApplicationELB"
  period              = 60
  statistic           = "Sum"
  threshold           = 0
  alarm_description   = "Alarm when ALB returns any 5xx errors."
  actions_enabled     = true
  alarm_actions       = [aws_sns_topic.notifications.arn]
  tags                = var.tags
}
