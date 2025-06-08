terraform {
  required_version = ">= 1.3.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
}

// modules/ecs_service/main.tf
// Módulo reutilizável para deploy de serviços ECS com Application Load Balancer (ALB),
// logging para S3/CloudWatch, e integração com roles, security groups e subnets.
// Usado tanto para a aplicação quanto para o Jenkins.

# --- Task Definition ---
resource "aws_ecs_task_definition" "this" {
  family                   = var.service_name
  network_mode             = "awsvpc"
  requires_compatibilities = ["EC2"]
  cpu                      = var.cpu
  memory                   = var.memory
  execution_role_arn       = var.execution_role_arn
  task_role_arn            = var.task_role_arn

  dynamic "volume" {
    for_each = var.efs_file_system_id != null ? [1] : []
    content {
      name = "efs-volume"
      efs_volume_configuration {
        file_system_id     = var.efs_file_system_id
        root_directory     = "/"
        transit_encryption = "ENABLED"
      }
    }
  }

  container_definitions = jsonencode([
    merge(
      {
        name      = var.service_name
        image     = var.image
        cpu       = var.cpu
        memory    = var.memory
        essential = true
        portMappings = [
          {
            containerPort = var.container_port
            hostPort      = var.container_port
          }
        ]
        logConfiguration = {
          logDriver = "awslogs"
          options = {
            awslogs-group         = var.log_group_name
            awslogs-region        = var.region
            awslogs-stream-prefix = var.service_name
          }
        }
        environment = var.environment
      },
      var.efs_file_system_id != null && var.efs_container_path != null ? {
        mountPoints = [
          {
            sourceVolume  = "efs-volume"
            containerPath = var.efs_container_path
            readOnly      = false
          }
        ]
      } : {}
    )
  ])
}

# --- Application Load Balancer (ALB) ---
resource "aws_lb" "this" {
  # checkov:skip=CKV2_AWS_28 reason="only jenkins need waf for Geo restriction"

  name                       = var.alb_name
  internal                   = var.alb_internal
  load_balancer_type         = "application"
  security_groups            = var.alb_security_groups
  subnets                    = var.alb_subnets
  drop_invalid_header_fields = true
  enable_deletion_protection = true

  access_logs {
    bucket  = var.alb_s3_bucket_name
    prefix  = var.alb_s3_prefix
    enabled = true
  }

  tags = merge(var.tags, { Name = var.alb_name })
}

# --- Target Group ---
resource "aws_lb_target_group" "this" {
  name     = "${var.alb_name}-tg"
  port     = var.target_group_port
  protocol = "HTTP"
  vpc_id   = var.vpc_id

  health_check {
    path                = var.health_check_path
    protocol            = "HTTP"
    matcher             = "200-399"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }

  target_type = "ip"
}

# --- Listener HTTPS (443) ---
resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.this.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS-1-2-2017-01"
  certificate_arn   = var.certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.this.arn
  }
}


# --- ECS Service ---
resource "aws_ecs_service" "this" {
  name            = var.service_name
  cluster         = var.cluster_arn
  task_definition = aws_ecs_task_definition.this.arn
  launch_type     = "EC2"
  desired_count   = var.desired_count

  network_configuration {
    subnets          = var.ecs_subnets
    security_groups  = var.ecs_security_groups
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.this.arn
    container_name   = var.service_name
    container_port   = var.container_port
  }

  depends_on = [aws_lb_listener.https]
}
