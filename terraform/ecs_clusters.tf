// ECS clusters for application and Jenkins, using EC2 (t3.micro) as container instances

// ECS cluster for the main application
resource "aws_ecs_cluster" "app" {
  name = "app-ecs-cluster"
  tags = var.tags

  setting {
    name  = "containerInsights"
    value = "enabled"
  }
}

// ECS cluster for Jenkins
resource "aws_ecs_cluster" "jenkins" {
  name = "jenkins-ecs-cluster"
  tags = var.tags

  setting {
    name  = "containerInsights"
    value = "enabled"
  }
}

// Auto Scaling Group for EC2 t3.micro (App)
resource "aws_launch_template" "app" {
  name_prefix   = "app-ecs-lt-"
  image_id      = data.aws_ami.ecs_optimized.id
  instance_type = "t3.micro"
  iam_instance_profile {
    name = aws_iam_instance_profile.ecs_instance.name
  }
  vpc_security_group_ids = [aws_security_group.app_ecs.id]
  user_data              = base64encode(data.template_file.ecs_user_data_app.rendered)
  tags                   = var.tags

  metadata_options {
    http_tokens   = "required"
    http_endpoint = "enabled"
  }
}

resource "aws_autoscaling_group" "app" {
  name                = "app-ecs-asg"
  min_size            = 2
  max_size            = 2
  desired_capacity    = 2
  vpc_zone_identifier = module.vpc_app.private_subnets
  launch_template {
    id      = aws_launch_template.app.id
    version = "$Latest"


  }
  tag {
    key                 = "Name"
    value               = "app-ecs-instance"
    propagate_at_launch = true
  }

}

// Auto Scaling Group for EC2 t3.micro (Jenkins)
resource "aws_launch_template" "jenkins" {
  name_prefix   = "jenkins-ecs-lt-"
  image_id      = data.aws_ami.ecs_optimized.id
  instance_type = "t3.micro"
  iam_instance_profile {
    name = aws_iam_instance_profile.ecs_instance.name
  }
  vpc_security_group_ids = [aws_security_group.jenkins_ecs.id]
  user_data              = base64encode(data.template_file.ecs_user_data_jenkins.rendered)
  tags                   = var.tags

  metadata_options {
    http_tokens   = "required"
    http_endpoint = "enabled"
  }
}

resource "aws_autoscaling_group" "jenkins" {
  name                = "jenkins-ecs-asg"
  min_size            = 2
  max_size            = 2
  desired_capacity    = 2
  vpc_zone_identifier = module.vpc_jenkins.private_subnets
  launch_template {
    id      = aws_launch_template.jenkins.id
    version = "$Latest"
  }
  tag {
    key                 = "Name"
    value               = "jenkins-ecs-instance"
    propagate_at_launch = true
  }
}

// ECS-optimized AMI (fetches the latest for the region)
data "aws_ami" "ecs_optimized" {
  most_recent = true
  owners      = ["591542846629"] // Amazon ECS AMI account
  filter {
    name   = "name"
    values = ["amzn2-ami-ecs-hvm-*-x86_64-ebs"]
  }
}

// User data to register instance in ECS cluster (App)
data "template_file" "ecs_user_data_app" {
  template = <<EOF
#!/bin/bash
echo ECS_CLUSTER=${aws_ecs_cluster.app.name} >> /etc/ecs/ecs.config
echo ECS_BACKEND_HOST=ecs.eu-central-1.amazonaws.com >> /etc/ecs/ecs.config
EOF
}

// User data to register instance in ECS cluster (Jenkins)
data "template_file" "ecs_user_data_jenkins" {
  template = <<EOF
#!/bin/bash
echo ECS_CLUSTER=${aws_ecs_cluster.jenkins.name} >> /etc/ecs/ecs.config
echo ECS_BACKEND_HOST=ecs.eu-central-1.amazonaws.com >> /etc/ecs/ecs.config
EOF
}

// Instance profile for EC2 ECS instances
resource "aws_iam_instance_profile" "ecs_instance" {
  name = "ecs-instance-profile"
  role = aws_iam_role.ecs_instance.name
}

// Outputs for ECS cluster ARNs
output "app_ecs_cluster_arn" {
  description = "ARN of the application ECS Cluster."
  value       = aws_ecs_cluster.app.arn
}

output "jenkins_ecs_cluster_arn" {
  description = "ARN of the Jenkins ECS Cluster."
  value       = aws_ecs_cluster.jenkins.arn
}
