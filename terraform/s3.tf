// Global S3 bucket for ALB, ECS, and pipeline logs

resource "aws_s3_bucket" "logs" {
  # Stores logs from ALB, ECS, and pipeline executions
  # checkov:skip=CKV_AWS_18 reason="Access logging not necessary for this bucket, as it is used for log storage only."
  # checkov:skip=CKV_AWS_21 reason="Don't need versioning for this bucket, as it is used for log storage only."
  # checkov:skip=CKV_AWS_145 reason="Its only for logs, so no need to enable encryption for these test deployment."
  # checkov:skip=CKV_AWS_144 reason="not necessary for this deployment"
  # checkov:skip=CKV2_AWS_61 reason="Ensure that an S3 bucket has a lifecycle configuration not necessary for this deployment, as it is used for log storage only."
  # checkov:skip=CKV2_AWS_62 reason="event notifications not necessary for this deployment, as it is used for log storage only."

  bucket        = "${replace(lower(var.tags.product), "[^a-z0-9-]", "")}-${replace(lower(var.tags.service), "[^a-z0-9-]", "")}-logs${random_id.suffix.hex}"
  force_destroy = true
  lifecycle {
    prevent_destroy = false
  }

  tags = var.tags
}
resource "aws_s3_bucket_public_access_block" "logs" {
  bucket                  = aws_s3_bucket.logs.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
// Random suffix for unique S3 bucket name
resource "random_id" "suffix" {
  # Ensures the S3 bucket name is globally unique
  byte_length = 4
}

// S3 bucket policy to allow ALB, ECS, and log delivery services to write logs
resource "aws_s3_bucket_policy" "logs_policy" {
  # Attaches a policy to the logs bucket for AWS service log delivery
  bucket = aws_s3_bucket.logs.id

  policy = data.aws_iam_policy_document.logs_policy.json
}

data "aws_iam_policy_document" "logs_policy" {
  # Policy document allowing specific AWS services to put logs in the bucket
  statement {
    sid    = "AllowALBAndECSLogging"
    effect = "Allow"
    principals {
      type = "Service"
      identifiers = [
        "delivery.logs.amazonaws.com",
        "ecs.amazonaws.com",
        "logdelivery.elasticloadbalancing.amazonaws.com"
      ]
    }
    actions = [
      "s3:PutObject"
    ]
    resources = [
      "${aws_s3_bucket.logs.arn}/*"
    ]
  }
}
