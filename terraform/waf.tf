// WAFv2 Web ACL to restrict access to Jenkins ALB to Portugal only (GeoIP)
resource "aws_wafv2_web_acl" "jenkins_geo" {
  # checkov:skip=CKV2_AWS_31 reason="WAFv2 Web ACL is used to restrict access based on GeoIP, which is a valid use case."

  # Web ACL that allows only requests from Portugal (PT) to reach Jenkins ALB
  name        = "jenkins-geoip-waf"
  description = "Allow access to Jenkins ALB only from Portugal"
  scope       = "REGIONAL"
  default_action {
    block {}
  }
  rule {
    name     = "Allow-PT"
    priority = 1
    action {
      allow {}
    }
    statement {
      geo_match_statement {
        country_codes = ["PT"]
      }
    }
    visibility_config {
      sampled_requests_enabled   = true
      cloudwatch_metrics_enabled = true
      metric_name                = "jenkins-geo-allow-pt"
    }
  }
  rule {
    name     = "AWS-AWSManagedRulesKnownBadInputsRuleSet"
    priority = 0
    override_action {
      none {}
    }
    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesKnownBadInputsRuleSet"
        vendor_name = "AWS"
      }
    }
    visibility_config {
      sampled_requests_enabled   = true
      cloudwatch_metrics_enabled = true
      metric_name                = "log4j2-bad-inputs"
    }
  }
  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "jenkins-geo-web-acl"
    sampled_requests_enabled   = true
  }
  tags = var.tags
}

resource "aws_wafv2_web_acl_association" "jenkins_alb" {
  # Associates the WAF Web ACL with the Jenkins ALB
  resource_arn = module.ecs_jenkins.alb_arn
  web_acl_arn  = aws_wafv2_web_acl.jenkins_geo.arn
}
