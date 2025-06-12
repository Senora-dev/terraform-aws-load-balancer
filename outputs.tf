################################################################################
# Load Balancer
################################################################################

output "id" {
  description = "The ID and ARN of the load balancer we created"
  value       = try(aws_lb.this[0].id, "")
}

output "arn" {
  description = "The ARN of the load balancer we created"
  value       = try(aws_lb.this[0].arn, "")
}

output "arn_suffix" {
  description = "ARN suffix of our load balancer - can be used with CloudWatch"
  value       = try(aws_lb.this[0].arn_suffix, "")
}

output "dns_name" {
  description = "The DNS name of the load balancer"
  value       = try(aws_lb.this[0].dns_name, "")
}

output "zone_id" {
  description = "The zone_id of the load balancer to assist with creating DNS records"
  value       = try(aws_lb.this[0].zone_id, "")
}

################################################################################
# Listener(s)
################################################################################

output "listeners" {
  description = "Map of listeners created and their attributes"
  value       = aws_lb_listener.this
}

output "listener_rules" {
  description = "Map of listener rules created and their attributes"
  value       = aws_lb_listener_rule.this
}

################################################################################
# Target Group(s)
################################################################################

output "target_groups" {
  description = "Map of target groups created and their attributes"
  value       = aws_lb_target_group.this
} 