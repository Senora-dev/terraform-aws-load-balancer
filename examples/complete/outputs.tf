################################################################################
# VPC
################################################################################

output "vpc_id" {
  description = "The ID of the VPC"
  value       = aws_vpc.main.id
}

output "public_subnet_ids" {
  description = "List of IDs of public subnets"
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "List of IDs of private subnets"
  value       = aws_subnet.private[*].id
}

################################################################################
# Security Groups
################################################################################

output "alb_security_group_id" {
  description = "The ID of the ALB security group"
  value       = aws_security_group.alb.id
}

output "backend_security_group_id" {
  description = "The ID of the backend security group"
  value       = aws_security_group.backend.id
}

################################################################################
# Load Balancer
################################################################################

output "alb_id" {
  description = "The ID of the load balancer"
  value       = module.alb.id
}

output "alb_arn" {
  description = "The ARN of the load balancer"
  value       = module.alb.arn
}

output "alb_dns_name" {
  description = "The DNS name of the load balancer"
  value       = module.alb.dns_name
}

output "alb_zone_id" {
  description = "The zone_id of the load balancer"
  value       = module.alb.zone_id
}

################################################################################
# Target Groups
################################################################################

output "target_group_arns" {
  description = "ARNs of the target groups"
  value       = { for k, v in module.alb.target_groups : k => v.arn }
}

output "target_group_names" {
  description = "Names of the target groups"
  value       = { for k, v in module.alb.target_groups : k => v.name }
}

################################################################################
# Listeners
################################################################################

output "http_listener_arn" {
  description = "The ARN of the HTTP listener"
  value       = module.alb.listeners["http"].arn
}

output "alb_listeners" {
  description = "Map of ALB listeners created and their attributes"
  value       = module.alb.listeners
}

output "alb_listener_rules" {
  description = "Map of ALB listener rules created and their attributes"
  value       = module.alb.listener_rules
}

output "alb_target_groups" {
  description = "Map of ALB target groups created and their attributes"
  value       = module.alb.target_groups
}

################################################################################
# S3 Access Logs
################################################################################

output "log_bucket_id" {
  description = "The ID of the S3 bucket for ALB access logs"
  value       = aws_s3_bucket.logs.id
}

output "log_bucket_arn" {
  description = "The ARN of the S3 bucket for ALB access logs"
  value       = aws_s3_bucket.logs.arn
}

# Certificate output is commented out until we re-enable HTTPS support
/*
################################################################################
# Certificate
################################################################################

output "certificate_arn" {
  description = "The ARN of the self-signed certificate"
  value       = aws_acm_certificate.this.arn
}
*/ 