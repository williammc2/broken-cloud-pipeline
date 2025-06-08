// variables.tf
// Variáveis de entrada para o módulo ECS/ALB reutilizável

variable "service_name" {
  description = "Nome do serviço ECS (app ou jenkins)"
  type        = string
}

variable "image" {
  description = "Imagem Docker a ser usada no container."
  type        = string
}

variable "cpu" {
  description = "CPU units para a task ECS."
  type        = number
  default     = 256
}

variable "memory" {
  description = "Memória (MiB) para a task ECS."
  type        = number
  default     = 512
}

variable "container_port" {
  description = "Porta exposta pelo container."
  type        = number
  default     = 8080
}

variable "execution_role_arn" {
  description = "ARN da role de execução da ECS task."
  type        = string
}

variable "task_role_arn" {
  description = "ARN da role da ECS task."
  type        = string
}

variable "log_group_name" {
  description = "Nome do grupo de logs do CloudWatch."
  type        = string
}

variable "region" {
  description = "Região AWS."
  type        = string
  default     = "eu-central-1"
}

variable "environment" {
  description = "Lista de variáveis de ambiente para o container."
  type = list(object({
    name  = string
    value = string
  }))
  default = []
}

variable "alb_name" {
  description = "Nome do Application Load Balancer."
  type        = string
}

variable "alb_subnets" {
  description = "Lista de subnets públicas para o ALB."
  type        = list(string)
}

variable "alb_security_groups" {
  description = "Lista de security groups para o ALB."
  type        = list(string)
}

variable "alb_internal" {
  description = "Se o ALB é interno (privado)."
  type        = bool
  default     = false
}

variable "alb_s3_bucket_name" {
  description = "Nome do bucket S3 para logs do ALB."
  type        = string
}

variable "alb_s3_prefix" {
  description = "Prefixo para logs do ALB no S3."
  type        = string
  default     = "alb-logs"
}

variable "certificate_arn" {
  description = "ARN do certificado ACM para HTTPS."
  type        = string
}

variable "target_group_port" {
  description = "Porta do Target Group (normalmente igual ao container_port)."
  type        = number
  default     = 8080
}

variable "health_check_path" {
  description = "Path para health check do Target Group."
  type        = string
  default     = "/"
}

variable "vpc_id" {
  description = "ID da VPC onde o Target Group será criado."
  type        = string
}

variable "cluster_arn" {
  description = "ARN do ECS Cluster onde o serviço será criado."
  type        = string
}

variable "desired_count" {
  description = "Número desejado de tasks ECS."
  type        = number
  default     = 2
}

variable "ecs_subnets" {
  description = "Lista de subnets privadas para as tasks ECS."
  type        = list(string)
}

variable "ecs_security_groups" {
  description = "Lista de security groups para as tasks ECS."
  type        = list(string)
}

variable "tags" {
  description = "Tags globais para todos os recursos do módulo."
  type        = map(string)
}

variable "efs_file_system_id" {
  type        = string
  description = "ID do EFS para montar no container (opcional)"
  default     = null
}

variable "efs_container_path" {
  type        = string
  description = "Caminho no container para montar o EFS (opcional)"
  default     = null
}
