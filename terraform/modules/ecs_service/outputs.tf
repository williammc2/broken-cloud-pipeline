// outputs.tf
// Outputs úteis do módulo ECS/ALB

output "service_name" {
  description = "Nome do serviço ECS criado."
  value       = aws_ecs_task_definition.this.family
}

output "task_definition_arn" {
  description = "ARN do ECS Task Definition."
  value       = aws_ecs_task_definition.this.arn
}

output "alb_dns_name" {
  description = "DNS público do Application Load Balancer."
  value       = aws_lb.this.dns_name
}

output "alb_arn" {
  description = "ARN do Application Load Balancer."
  value       = aws_lb.this.arn
}

output "target_group_arn" {
  description = "ARN do Target Group do ALB."
  value       = aws_lb_target_group.this.arn
}

output "listener_arn" {
  description = "ARN do Listener HTTPS do ALB."
  value       = aws_lb_listener.https.arn
}
