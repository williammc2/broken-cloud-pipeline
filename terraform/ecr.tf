// ECR repositories for Docker images (app)

resource "aws_ecr_repository" "app" {
  name                 = "${var.tags.product}-app"
  image_tag_mutability = "IMMUTABLE"
  tags                 = var.tags
  image_scanning_configuration {
    scan_on_push = true
  }

  encryption_configuration {
    encryption_type = "KMS"
  }
}
