################################################################################
# Load Balancer
################################################################################

variable "create" {
  description = "Determines whether resources will be created"
  type        = bool
  default     = true
}

variable "name" {
  description = "The name of the LB. This name must be unique within your AWS account"
  type        = string
}

variable "use_name_prefix" {
  description = "Determines whether to use `name` as is or create a unique name beginning with the `name` as the prefix"
  type        = bool
  default     = true
}

variable "load_balancer_type" {
  description = "The type of load balancer to create. Possible values are application, gateway, or network"
  type        = string
  default     = "application"
}

variable "internal" {
  description = "Determines if the load balancer is internal or externally facing"
  type        = bool
  default     = false
}

variable "security_groups" {
  description = "A list of security group IDs to assign to the LB"
  type        = list(string)
  default     = []
}

variable "subnets" {
  description = "A list of subnet IDs to attach to the LB"
  type        = list(string)
  default     = []
}

variable "subnet_mappings" {
  description = "A list of subnet mapping blocks describing subnets to attach to network load balancer"
  type = list(object({
    subnet_id            = string
    allocation_id        = optional(string)
    private_ipv4_address = optional(string)
    ipv6_address        = optional(string)
  }))
  default = []
}

variable "vpc_id" {
  description = "VPC id where the load balancer and other resources will be deployed"
  type        = string
  default     = null
}

variable "idle_timeout" {
  description = "The time in seconds that the connection is allowed to be idle"
  type        = number
  default     = 60
}

variable "enable_cross_zone_load_balancing" {
  description = "Indicates whether cross zone load balancing should be enabled in application load balancers"
  type        = bool
  default     = false
}

variable "enable_deletion_protection" {
  description = "If true, deletion of the load balancer will be disabled via the AWS API"
  type        = bool
  default     = false
}

variable "enable_http2" {
  description = "Indicates whether HTTP/2 is enabled in application load balancers"
  type        = bool
  default     = true
}

variable "ip_address_type" {
  description = "The type of IP addresses used by the subnets for your load balancer. The possible values are ipv4 and dualstack"
  type        = string
  default     = "ipv4"
}

variable "drop_invalid_header_fields" {
  description = "Indicates whether invalid header fields are dropped in application load balancers"
  type        = bool
  default     = false
}

variable "preserve_host_header" {
  description = "Indicates whether Host header should be preserved and forwarded to targets without any change"
  type        = bool
  default     = false
}

variable "access_logs" {
  description = "Map containing access logging configuration for load balancer"
  type        = map(string)
  default     = {}
}

################################################################################
# Listener
################################################################################

variable "listeners" {
  description = "Map of listener configurations to create"
  type        = any
  default     = {}
}

variable "listener_rules" {
  description = "Map of listener rules to create"
  type        = any
  default     = {}
}

################################################################################
# Target Group
################################################################################

variable "target_groups" {
  description = "Map of target group configurations to create"
  type        = any
  default     = {}
}

################################################################################
# Common
################################################################################

variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
  default     = {}
}

variable "lb_tags" {
  description = "A map of tags to add to the load balancer"
  type        = map(string)
  default     = {}
}

variable "target_group_tags" {
  description = "A map of tags to add to all target groups"
  type        = map(string)
  default     = {}
}

variable "listener_tags" {
  description = "A map of tags to add to all listeners"
  type        = map(string)
  default     = {}
}

variable "listener_rule_tags" {
  description = "A map of tags to add to all listener rules"
  type        = map(string)
  default     = {}
}

variable "timeouts" {
  description = "Create, update, and delete timeout configurations for the load balancer"
  type        = map(string)
  default     = {}
} 