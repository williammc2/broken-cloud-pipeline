# ACM certificate for Jenkins ALB (jenkins.<domain_name>)
resource "aws_acm_certificate" "jenkins" {
  # Issues a certificate for Jenkins using DNS validation
  domain_name       = "jenkins.${var.domain_name}"
  validation_method = "DNS"
  tags              = var.tags

  lifecycle {
    create_before_destroy = true
  }
}

# ACM certificate for App ALB (hw.<domain_name>)
resource "aws_acm_certificate" "hw" {
  # Issues a certificate for the main app using DNS validation
  domain_name       = "hw.${var.domain_name}"
  validation_method = "DNS"
  tags              = var.tags

  lifecycle {
    create_before_destroy = true
  }
}
