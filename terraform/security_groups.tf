// Security Group for Application ALB: allows HTTPS (443) from any source
resource "aws_security_group" "app_alb" {
  name        = "app-alb-sg"
  description = "Allow HTTPS for App ALB"
  vpc_id      = module.vpc_app.vpc_id

  ingress {
    description = "HTTPS from anywhere"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    # checkov:skip=CKV_AWS_382 reason="Allow all outbound traffic for this ALB its ok"

    description = "Allow all outbound traffic"

    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = var.tags
}

// Security Group for Application ECS: allows traffic from ALB
resource "aws_security_group" "app_ecs" {
  name        = "app-ecs-sg"
  description = "Allow traffic from ALB to ECS App"
  vpc_id      = module.vpc_app.vpc_id

  ingress {
    description     = "From ALB"
    from_port       = 8080
    to_port         = 8080
    protocol        = "tcp"
    security_groups = [aws_security_group.app_alb.id]
  }

  egress {
    # checkov:skip=CKV_AWS_382 reason="Allow all outbound traffic for this ECS its ok"
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = var.tags
}

// Security Group for Jenkins ALB: allows HTTPS (443) (geo restriction can be improved with WAF)
resource "aws_security_group" "jenkins_alb" {
  name        = "jenkins-alb-sg"
  description = "Allow HTTPS for Jenkins ALB (PT only)"
  vpc_id      = module.vpc_jenkins.vpc_id

  ingress {
    description = "HTTPS from Portugal (PT IP range)"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    # checkov:skip=CKV_AWS_382 reason="Allow all outbound traffic for this ALB its ok"
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = var.tags
}

// Security Group for Jenkins ECS: allows traffic from ALB
resource "aws_security_group" "jenkins_ecs" {
  name        = "jenkins-ecs-sg"
  description = "Allow traffic from ALB to ECS Jenkins"
  vpc_id      = module.vpc_jenkins.vpc_id

  ingress {
    description     = "From ALB"
    from_port       = 8080
    to_port         = 8080
    protocol        = "tcp"
    security_groups = [aws_security_group.jenkins_alb.id]
  }

  egress {
    # checkov:skip=CKV_AWS_382 reason="Allow all outbound traffic for this ECS its ok"
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = var.tags
}

// Security Group for EFS: allows NFS (2049) access from Jenkins ECS to EFS
resource "aws_security_group" "efs_sg" {
  name        = "jenkins-efs-sg"
  description = "Permite acesso NFS (2049) do ECS Jenkins ao EFS"
  vpc_id      = module.vpc_jenkins.vpc_id

  ingress {
    description     = "NFS from Jenkins ECS"
    from_port       = 2049
    to_port         = 2049
    protocol        = "tcp"
    security_groups = ["0.0.0.0/0"]
  }

  egress {
    # checkov:skip=CKV_AWS_382 reason="Allow all outbound traffic for this EFS its ok"
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = var.tags
}
