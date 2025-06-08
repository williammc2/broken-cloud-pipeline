# EFS file system for Jenkins persistent data
resource "aws_efs_file_system" "jenkins_data" {
  # Provides a persistent, shared file system for Jenkins data
  tags       = var.tags
  encrypted  = true
  kms_key_id = aws_kms_key.cloud.arn
}


# EFS mount targets for Jenkins (one per private subnet)
resource "aws_efs_mount_target" "jenkins" {
  for_each = { for idx, subnet_id in module.vpc_jenkins.private_subnets : idx => subnet_id }

  file_system_id  = aws_efs_file_system.jenkins_data.id
  subnet_id       = each.value
  security_groups = [aws_security_group.efs_sg.id]
}
