# Defines required providers and configures the AWS provider with default tags for all resources.

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
    template = {
      source  = "hashicorp/template"
      version = ">= 2.2.0"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.0"
    }
  }
  required_version = ">= 1.3.0"
}

provider "aws" {
  region = "eu-central-1" # AWS region for all resources
  default_tags {
    tags = {
      environment = var.tags.environment
      product     = var.tags.product
      service     = var.tags.service
    }
  }
}
