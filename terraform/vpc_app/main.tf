terraform {
  required_version = ">= 1.3.0"
}

// VPC for application, created with terraform-aws-modules/vpc/aws
// Includes 2 public and 2 private subnets for high availability
module "vpc" {
  # checkov:skip=CKV_TF_1 reason="Terraform Registry module already uses version"

  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name = "app-vpc"
  cidr = "10.40.0.0/16"

  azs             = ["eu-central-1a", "eu-central-1b"]
  public_subnets  = ["10.40.1.0/24", "10.40.2.0/24"]
  private_subnets = ["10.40.101.0/24", "10.40.102.0/24"]

  enable_dns_hostnames = true
  enable_dns_support   = true
  enable_nat_gateway   = true
  single_nat_gateway   = true

  tags = var.tags
}
