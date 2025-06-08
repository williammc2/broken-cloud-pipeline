terraform {
  required_version = ">= 1.3.0"
}
// This file orchestrates modules and global resources for the project.
// Calls VPC, ECS, and global resources like IAM, S3, ECR, SNS, Route53, CloudWatch.

// 1. Create VPCs (prerequisite for peering and network resources)
module "vpc_app" {
  source = "./vpc_app"
  tags   = var.tags
  // VPC for the main application
}

module "vpc_jenkins" {
  source = "./vpc_jenkins"
  tags   = var.tags
  // VPC for Jenkins
}

// 2. Create VPC peering between the VPCs (depends on VPCs)
resource "aws_vpc_peering_connection" "vpc_peering" {
  vpc_id      = module.vpc_app.vpc_id
  peer_vpc_id = module.vpc_jenkins.vpc_id
  auto_accept = true
  tags        = merge(var.tags, { Name = "app-jenkins-peering" })
  depends_on  = [module.vpc_app, module.vpc_jenkins]
}

// Route from App VPC to Jenkins VPC
resource "aws_route" "app_to_jenkins" {
  count                     = length(module.vpc_app.private_route_table_ids)
  route_table_id            = module.vpc_app.private_route_table_ids[count.index]
  destination_cidr_block    = module.vpc_jenkins.cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection.vpc_peering.id
}

// Route from Jenkins VPC to App VPC
resource "aws_route" "jenkins_to_app" {
  count                     = length(module.vpc_jenkins.private_route_table_ids)
  route_table_id            = module.vpc_jenkins.private_route_table_ids[count.index]
  destination_cidr_block    = module.vpc_app.cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection.vpc_peering.id
}

// ECS service module for the main application
module "ecs_app" {
  source = "./modules/ecs_service"

  service_name        = "app-service"
  image               = "infrastructureascode/hello-world:latest"
  cpu                 = 1024 // FLAW: ECS task CPU over-allocated, wastes resources
  memory              = 512
  container_port      = 8080
  execution_role_arn  = aws_iam_role.ecs_task_app_execution.arn
  task_role_arn       = aws_iam_role.ecs_task_app.arn
  log_group_name      = "/ecs/${var.tags.product}-app"
  region              = local.region
  environment         = []
  tags                = var.tags
  certificate_arn     = aws_acm_certificate.hw.arn
  alb_name            = "app-alb"
  alb_subnets         = module.vpc_app.public_subnets
  alb_security_groups = [aws_security_group.app_alb.id]
  alb_internal        = false
  alb_s3_prefix       = "alb-app-logs"
  alb_s3_bucket_name  = aws_s3_bucket.logs.bucket
  target_group_port   = 8080
  health_check_path   = "/"
  vpc_id              = module.vpc_app.vpc_id

  cluster_arn         = aws_ecs_cluster.app.arn
  desired_count       = 2
  ecs_subnets         = module.vpc_app.private_subnets
  ecs_security_groups = [aws_security_group.app_ecs.id]
}

// ECS service module for Jenkins (with EFS volume)
module "ecs_jenkins" {
  source = "./modules/ecs_service"

  service_name        = "jenkins-service"
  image               = "jenkins/jenkins:lts"
  cpu                 = 256
  memory              = 512
  container_port      = 8080
  execution_role_arn  = aws_iam_role.ecs_task_jenkins_execution.arn
  task_role_arn       = aws_iam_role.ecs_task_jenkins.arn
  log_group_name      = "/ecs/${var.tags.product}-jenkins"
  region              = local.region
  environment         = []
  tags                = var.tags
  certificate_arn     = aws_acm_certificate.jenkins.arn
  alb_name            = "jenkins-alb"
  alb_subnets         = module.vpc_jenkins.public_subnets
  alb_security_groups = [aws_security_group.jenkins_alb.id]
  alb_internal        = false
  alb_s3_prefix       = "alb-jenkins-logs"
  alb_s3_bucket_name  = aws_s3_bucket.logs.bucket
  target_group_port   = 8080
  health_check_path   = "/login"
  vpc_id              = module.vpc_jenkins.vpc_id

  cluster_arn         = aws_ecs_cluster.jenkins.arn
  desired_count       = 1
  ecs_subnets         = module.vpc_jenkins.private_subnets
  ecs_security_groups = [aws_security_group.jenkins_ecs.id]

  efs_file_system_id = aws_efs_file_system.jenkins_data.id
  efs_container_path = "/var/jenkins_home"
}
