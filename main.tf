locals {
  create_alb = var.load_balancer_type == "application"
  create_nlb = var.load_balancer_type == "network"
}

################################################################################
# Load Balancer
################################################################################

resource "aws_lb" "this" {
  count = var.create ? 1 : 0

  name               = var.use_name_prefix ? null : var.name
  name_prefix        = var.use_name_prefix ? "${var.name}-" : null
  load_balancer_type = var.load_balancer_type
  internal           = var.internal
  security_groups    = var.load_balancer_type == "network" ? null : var.security_groups
  subnets           = var.subnets

  idle_timeout                     = var.load_balancer_type == "network" ? null : var.idle_timeout
  enable_cross_zone_load_balancing = var.enable_cross_zone_load_balancing
  enable_deletion_protection       = var.enable_deletion_protection
  enable_http2                     = var.load_balancer_type == "network" ? null : var.enable_http2
  ip_address_type                 = var.ip_address_type
  drop_invalid_header_fields      = var.load_balancer_type == "network" ? null : var.drop_invalid_header_fields
  preserve_host_header           = var.load_balancer_type == "network" ? null : var.preserve_host_header

  dynamic "access_logs" {
    for_each = length(var.access_logs) > 0 ? [var.access_logs] : []

    content {
      bucket  = access_logs.value.bucket
      prefix  = try(access_logs.value.prefix, null)
      enabled = try(access_logs.value.enabled, true)
    }
  }

  dynamic "subnet_mapping" {
    for_each = var.subnet_mappings

    content {
      subnet_id            = subnet_mapping.value.subnet_id
      allocation_id        = try(subnet_mapping.value.allocation_id, null)
      private_ipv4_address = try(subnet_mapping.value.private_ipv4_address, null)
      ipv6_address        = try(subnet_mapping.value.ipv6_address, null)
    }
  }

  tags = merge(
    var.tags,
    {
      Name = var.name
    },
  )

  timeouts {
    create = lookup(var.timeouts, "create", "10m")
    update = lookup(var.timeouts, "update", "10m")
    delete = lookup(var.timeouts, "delete", "10m")
  }
}

################################################################################
# Listeners
################################################################################

resource "aws_lb_listener" "this" {
  for_each = { for k, v in var.listeners : k => v if var.create }

  load_balancer_arn = aws_lb.this[0].arn
  port              = try(each.value.port, null)
  protocol          = try(each.value.protocol, null)
  ssl_policy        = try(each.value.ssl_policy, null)
  certificate_arn   = try(each.value.certificate_arn, null)
  alpn_policy       = try(each.value.alpn_policy, null)

  dynamic "default_action" {
    for_each = try([each.value.default_action], [])

    content {
      type             = try(default_action.value.type, null)
      target_group_arn = try(default_action.value.target_group_arn, null)

      dynamic "fixed_response" {
        for_each = try([default_action.value.fixed_response], [])

        content {
          content_type = fixed_response.value.content_type
          message_body = try(fixed_response.value.message_body, null)
          status_code  = try(fixed_response.value.status_code, null)
        }
      }

      dynamic "forward" {
        for_each = try([default_action.value.forward], [])

        content {
          dynamic "target_group" {
            for_each = try(forward.value.target_groups, [])

            content {
              arn    = target_group.value.arn
              weight = try(target_group.value.weight, null)
            }
          }

          dynamic "stickiness" {
            for_each = try([forward.value.stickiness], [])

            content {
              duration = try(stickiness.value.duration, null)
              enabled  = try(stickiness.value.enabled, null)
            }
          }
        }
      }

      dynamic "redirect" {
        for_each = try([default_action.value.redirect], [])

        content {
          path        = try(redirect.value.path, null)
          host        = try(redirect.value.host, null)
          port        = try(redirect.value.port, null)
          protocol    = try(redirect.value.protocol, null)
          query       = try(redirect.value.query, null)
          status_code = redirect.value.status_code
        }
      }
    }
  }

  tags = merge(
    var.tags,
    try(each.value.tags, {}),
    {
      Name = try(each.value.name, each.key)
    },
  )
}

################################################################################
# Listener Rules
################################################################################

resource "aws_lb_listener_rule" "this" {
  for_each = { for k, v in var.listener_rules : k => v if var.create }

  listener_arn = aws_lb_listener.this[each.value.listener_key].arn
  priority     = try(each.value.priority, null)

  dynamic "condition" {
    for_each = try(each.value.conditions, [])

    content {
      dynamic "path_pattern" {
        for_each = try([condition.value.path_pattern], [])

        content {
          values = path_pattern.value.values
        }
      }

      dynamic "host_header" {
        for_each = try([condition.value.host_header], [])

        content {
          values = host_header.value.values
        }
      }

      dynamic "http_header" {
        for_each = try([condition.value.http_header], [])

        content {
          http_header_name = http_header.value.http_header_name
          values          = http_header.value.values
        }
      }

      dynamic "query_string" {
        for_each = try([condition.value.query_string], [])

        content {
          key   = try(query_string.value.key, null)
          value = query_string.value.value
        }
      }

      dynamic "source_ip" {
        for_each = try([condition.value.source_ip], [])

        content {
          values = source_ip.value.values
        }
      }
    }
  }

  dynamic "action" {
    for_each = try([each.value.action], [])

    content {
      type             = action.value.type
      target_group_arn = try(action.value.target_group_arn, null)

      dynamic "fixed_response" {
        for_each = try([action.value.fixed_response], [])

        content {
          content_type = fixed_response.value.content_type
          message_body = try(fixed_response.value.message_body, null)
          status_code  = try(fixed_response.value.status_code, null)
        }
      }

      dynamic "forward" {
        for_each = try([action.value.forward], [])

        content {
          dynamic "target_group" {
            for_each = try(forward.value.target_groups, [])

            content {
              arn    = target_group.value.arn
              weight = try(target_group.value.weight, null)
            }
          }

          dynamic "stickiness" {
            for_each = try([forward.value.stickiness], [])

            content {
              duration = try(stickiness.value.duration, null)
              enabled  = try(stickiness.value.enabled, null)
            }
          }
        }
      }

      dynamic "redirect" {
        for_each = try([action.value.redirect], [])

        content {
          path        = try(redirect.value.path, null)
          host        = try(redirect.value.host, null)
          port        = try(redirect.value.port, null)
          protocol    = try(redirect.value.protocol, null)
          query       = try(redirect.value.query, null)
          status_code = redirect.value.status_code
        }
      }
    }
  }

  tags = merge(
    var.tags,
    try(each.value.tags, {}),
    {
      Name = try(each.value.name, each.key)
    },
  )
}

################################################################################
# Target Groups
################################################################################

resource "aws_lb_target_group" "this" {
  for_each = { for k, v in var.target_groups : k => v if var.create }

  name                               = try(each.value.name, null)
  name_prefix                        = try(each.value.name_prefix, null)
  port                              = try(each.value.port, null)
  protocol                          = try(each.value.protocol, null)
  protocol_version                  = try(each.value.protocol_version, null)
  target_type                       = try(each.value.target_type, null)
  vpc_id                            = try(each.value.vpc_id, var.vpc_id)
  connection_termination            = try(each.value.connection_termination, null)
  deregistration_delay             = try(each.value.deregistration_delay, null)
  slow_start                       = try(each.value.slow_start, null)
  proxy_protocol_v2                = try(each.value.proxy_protocol_v2, null)
  lambda_multi_value_headers_enabled = try(each.value.lambda_multi_value_headers_enabled, null)
  load_balancing_algorithm_type     = try(each.value.load_balancing_algorithm_type, null)
  preserve_client_ip              = try(each.value.preserve_client_ip, null)
  ip_address_type                 = try(each.value.ip_address_type, null)

  dynamic "health_check" {
    for_each = try([each.value.health_check], [])

    content {
      enabled             = try(health_check.value.enabled, null)
      healthy_threshold   = try(health_check.value.healthy_threshold, null)
      interval           = try(health_check.value.interval, null)
      matcher            = try(health_check.value.matcher, null)
      path               = try(health_check.value.path, null)
      port               = try(health_check.value.port, null)
      protocol           = try(health_check.value.protocol, null)
      timeout            = try(health_check.value.timeout, null)
      unhealthy_threshold = try(health_check.value.unhealthy_threshold, null)
    }
  }

  dynamic "stickiness" {
    for_each = try([each.value.stickiness], [])

    content {
      enabled         = try(stickiness.value.enabled, null)
      type            = stickiness.value.type
      cookie_duration = try(stickiness.value.cookie_duration, null)
      cookie_name     = try(stickiness.value.cookie_name, null)
    }
  }

  tags = merge(
    var.tags,
    try(each.value.tags, {}),
    {
      Name = try(each.value.name, try(each.value.name_prefix, null))
    },
  )

  lifecycle {
    create_before_destroy = true
  }
} 