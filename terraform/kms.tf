// KMS key
resource "aws_kms_key" "cloud" {
  # checkov:skip=CKV2_AWS_64 reason="not necessary for this deployment"

  // Encryption key for CloudWatch logs and other resources
  description         = "KMS key"
  enable_key_rotation = true
  tags                = var.tags
}
