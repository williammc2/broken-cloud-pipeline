// IAM roles and policies for ECS tasks (app and Jenkins) and EC2 instances

// Role for ECS Task (App)
resource "aws_iam_role" "ecs_task_app" {
  name               = "${var.tags.product}-ecs-task-app-role"
  assume_role_policy = data.aws_iam_policy_document.ecs_task_assume_role.json
  tags               = var.tags
}

// Role for ECS Task (Jenkins)
resource "aws_iam_role" "ecs_task_jenkins" {
  name               = "${var.tags.product}-ecs-task-jenkins-role"
  assume_role_policy = data.aws_iam_policy_document.ecs_task_assume_role.json
  tags               = var.tags
}

// Role for EC2 instances (ECS container instances)
resource "aws_iam_role" "ecs_instance" {
  name               = "${var.tags.product}-ecs-instance-role"
  assume_role_policy = data.aws_iam_policy_document.ec2_assume_role.json
  tags               = var.tags
}

// Role for execution ECS Task (App)
resource "aws_iam_role" "ecs_task_app_execution" {
  name               = "${var.tags.product}-ecs-task-app-execution-role"
  assume_role_policy = data.aws_iam_policy_document.ecs_task_execution_assume_role.json
  tags               = var.tags
}

// Role for execution ECS Task (Jenkins)
resource "aws_iam_role" "ecs_task_jenkins_execution" {
  name               = "${var.tags.product}-ecs-task-jenkins-execution-role"
  assume_role_policy = data.aws_iam_policy_document.ecs_task_execution_assume_role.json
  tags               = var.tags
}

// Assume role policies

data "aws_iam_policy_document" "ecs_task_assume_role" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}

data "aws_iam_policy_document" "ec2_assume_role" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}

data "aws_iam_policy_document" "ecs_task_execution_assume_role" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}

// Policies for ECS tasks (App & Jenkins)
resource "aws_iam_policy" "ecs_task_policy" {
  name        = "${var.tags.product}-ecs-task-policy"
  description = "Policy for ECS tasks to access ECR, CloudWatch, S3, and SNS."
  policy      = data.aws_iam_policy_document.ecs_task_policy.json
}

data "aws_iam_policy_document" "ecs_task_policy" {
  statement {
    effect = "Allow"
    actions = [
      "ecr:GetAuthorizationToken",
      "ecr:BatchCheckLayerAvailability",
      "ecr:GetDownloadUrlForLayer",
      "ecr:BatchGetImage"
    ]
    resources = [aws_ecr_repository.app.arn]
  }
  statement {
    effect = "Allow"
    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "logs:CreateLogGroup"
    ]
    resources = [
      "arn:aws:logs:${local.region}:${var.account_id}:log-group:/ecs/*"
    ]
  }
  statement {
    effect = "Allow"
    actions = [
      "s3:PutObject"
    ]
    resources = ["${aws_s3_bucket.logs.arn}/*"]
    condition {
      test     = "StringEquals"
      variable = "s3:x-amz-server-side-encryption"
      values   = ["AES256"]
    }
  }
  statement {
    effect = "Allow"
    actions = [
      "sns:Publish"
    ]
    resources = [aws_sns_topic.notifications.arn]
  }
}

// Attach policy to ECS task roles
resource "aws_iam_role_policy_attachment" "ecs_task_app_attach" {
  role       = aws_iam_role.ecs_task_app.name
  policy_arn = aws_iam_policy.ecs_task_policy.arn
}

resource "aws_iam_role_policy_attachment" "ecs_task_jenkins_attach" {
  role       = aws_iam_role.ecs_task_jenkins.name
  policy_arn = aws_iam_policy.ecs_task_policy.arn
}

// Policy for EC2 instance role (ECS container instances)
resource "aws_iam_policy" "ecs_instance_policy" {
  name        = "${var.tags.product}-ecs-instance-policy"
  description = "Policy for ECS container instances to join ECS cluster, access ECR, and write logs."
  policy      = data.aws_iam_policy_document.ecs_instance_policy.json
}

data "aws_iam_policy_document" "ecs_instance_policy" {
  statement {
    effect = "Allow"
    actions = [
      "ecs:CreateCluster",
      "ecs:DeregisterContainerInstance",
      "ecs:DiscoverPollEndpoint",
      "ecs:Poll",
      "ecs:RegisterContainerInstance",
      "ecs:StartTelemetrySession",
      "ecs:UpdateContainerInstancesState",
      "ecs:Submit*"
    ]
    resources = [aws_ecs_cluster.app.arn, aws_ecs_cluster.jenkins.arn]
  }
  statement {
    effect = "Allow"
    actions = [
      "ecr:GetAuthorizationToken",
      "ecr:BatchCheckLayerAvailability",
      "ecr:GetDownloadUrlForLayer",
      "ecr:BatchGetImage"
    ]
    resources = [aws_ecr_repository.app.arn]
  }
  statement {
    effect = "Allow"
    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "logs:CreateLogGroup"
    ]
    resources = [
      "arn:aws:logs:${local.region}:${var.account_id}:log-group:/ecs/*"
    ]
  }
}

resource "aws_iam_role_policy_attachment" "ecs_instance_attach" {
  role       = aws_iam_role.ecs_instance.name
  policy_arn = aws_iam_policy.ecs_instance_policy.arn
}

resource "aws_iam_role_policy_attachment" "ecs_instance_managed_attach" {
  role       = aws_iam_role.ecs_instance.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}

output "ecs_task_app_role_arn" {
  description = "ARN of the execution/task role for the application ECS Task."
  value       = aws_iam_role.ecs_task_app.arn
}

output "ecs_task_jenkins_role_arn" {
  description = "ARN of the execution/task role for the Jenkins ECS Task."
  value       = aws_iam_role.ecs_task_jenkins.arn
}
