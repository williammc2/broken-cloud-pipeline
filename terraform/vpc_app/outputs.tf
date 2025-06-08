// Application VPC outputs
output "vpc_id" {
  description = "ID of the application VPC."
  value       = module.vpc.vpc_id
}

output "private_subnets" {
  description = "List of private subnets in the application VPC."
  value       = module.vpc.private_subnets
}

output "public_subnets" {
  description = "List of public subnets in the application VPC."
  value       = module.vpc.public_subnets
}

output "private_route_table_ids" {
  description = "IDs of the private route tables in the application VPC."
  value       = module.vpc.private_route_table_ids
}

output "cidr_block" {
  description = "CIDR block of the application VPC."
  value       = module.vpc.vpc_cidr_block
}
