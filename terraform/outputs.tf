// Global outputs for the project. Include endpoints, ARNs, and other important values for integration and validation.

output "app_alb_sg_id" {
  description = "ID of the Application ALB Security Group."
  value       = aws_security_group.app_alb.id
}

output "app_ecs_sg_id" {
  description = "ID of the Application ECS Security Group."
  value       = aws_security_group.app_ecs.id
}

output "jenkins_alb_sg_id" {
  description = "ID of the Jenkins ALB Security Group."
  value       = aws_security_group.jenkins_alb.id
}

output "jenkins_ecs_sg_id" {
  description = "ID of the Jenkins ECS Security Group."
  value       = aws_security_group.jenkins_ecs.id
}
