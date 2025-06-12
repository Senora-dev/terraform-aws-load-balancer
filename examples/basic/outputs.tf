output "vpc_id" {
  description = "The ID of the VPC"
  value       = aws_vpc.main.id
}

output "alb_dns_name" {
  description = "The DNS name of the load balancer"
  value       = module.alb.dns_name
}

output "alb_arn" {
  description = "The ARN of the load balancer"
  value       = module.alb.arn
}

output "alb_zone_id" {
  description = "The zone_id of the load balancer"
  value       = module.alb.zone_id
}

output "target_group_arn" {
  description = "The ARN of the target group"
  value       = module.alb.target_groups["main"].arn
}

output "security_group_id" {
  description = "The ID of the security group"
  value       = aws_security_group.alb.id
} 