// Public hosted zone for DNS (Route53)

resource "aws_route53_zone" "public" {
  # checkov:skip=CKV2_AWS_38 reason="Not necessary to enable DNSSEC for this public hosted zone, as it is not used for sensitive data or critical applications."

  name    = var.domain_name
  comment = "Public hosted zone for cloud pipeline."
  tags    = var.tags
}
resource "aws_cloudwatch_log_group" "route53_query_logs" {
  name              = "/aws/route53/${var.domain_name}-query-logs"
  retention_in_days = 365
  kms_key_id        = aws_kms_key.cloud.arn
}
resource "aws_route53_query_log" "public" {
  zone_id                  = aws_route53_zone.public.id
  cloudwatch_log_group_arn = aws_cloudwatch_log_group.route53_query_logs.arn
}
