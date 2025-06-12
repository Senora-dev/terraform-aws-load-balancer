# AWS Load Balancer Terraform module

Terraform module which creates Application and Network Load Balancer resources on AWS.

## Features

- Supports both Application Load Balancer (ALB) and Network Load Balancer (NLB)
- Conditional creation of resources
- Support for HTTP/HTTPS/TCP/TLS listeners
- Support for ALB listener rules with various conditions
- Support for target groups with customizable health checks
- Access logging to S3 bucket
- Subnet mapping with optional EIP allocation for NLB
- Security group management for ALB
- Tags propagation

## Usage

### Application Load Balancer (ALB)

```hcl
module "alb" {
  source = "terraform-aws-modules/load-balancer/aws"

  name               = "my-alb"
  load_balancer_type = "application"
  vpc_id             = "vpc-abcde012"
  subnets            = ["subnet-abcde012", "subnet-bcde012a"]
  security_groups    = ["sg-edcd9784", "sg-edcd9785"]

  access_logs = {
    bucket = "my-alb-logs"
  }

  target_groups = {
    ex-instance = {
      name_prefix      = "h1"
      protocol        = "HTTP"
      port            = 80
      target_type     = "instance"
      
      health_check = {
        enabled             = true
        interval           = 30
        path               = "/health"
        port               = "traffic-port"
        healthy_threshold   = 3
        unhealthy_threshold = 3
        timeout            = 6
        protocol          = "HTTP"
        matcher           = "200-399"
      }
    }
  }

  https_listeners = {
    ex-https = {
      port               = 443
      protocol          = "HTTPS"
      certificate_arn   = "arn:aws:acm:eu-west-1:0123456789012:certificate/abc123"
      
      default_action = {
        type             = "forward"
        target_group_arn = "arn:aws:elasticloadbalancing:eu-west-1:0123456789012:targetgroup/ex-instance/1234567890123"
      }
    }
  }

  http_tcp_listeners = {
    ex-http-https-redirect = {
      port     = 80
      protocol = "HTTP"
      
      default_action = {
        type = "redirect"
        redirect = {
          port        = "443"
          protocol    = "HTTPS"
          status_code = "HTTP_301"
        }
      }
    }
  }

  tags = {
    Environment = "Production"
    Project     = "Example"
  }
}
```

### Network Load Balancer (NLB)

```hcl
module "nlb" {
  source = "terraform-aws-modules/load-balancer/aws"

  name               = "my-nlb"
  load_balancer_type = "network"
  vpc_id             = "vpc-abcde012"

  subnet_mappings = [
    {
      subnet_id     = "subnet-abcde012"
      allocation_id = "eipalloc-abcde012"
    },
    {
      subnet_id     = "subnet-bcde012a"
      allocation_id = "eipalloc-bcde012a"
    }
  ]

  target_groups = {
    ex-tcp = {
      name_prefix      = "tcp"
      protocol        = "TCP"
      port            = 80
      target_type     = "instance"
      
      health_check = {
        enabled             = true
        interval           = 30
        port               = "traffic-port"
        protocol          = "TCP"
        healthy_threshold   = 3
        unhealthy_threshold = 3
      }
    }
  }

  listeners = {
    ex-tcp = {
      port     = 80
      protocol = "TCP"
      
      default_action = {
        type             = "forward"
        target_group_arn = "arn:aws:elasticloadbalancing:eu-west-1:0123456789012:targetgroup/ex-tcp/1234567890123"
      }
    }
  }

  tags = {
    Environment = "Production"
    Project     = "Example"
  }
}
```

## Examples

- [Complete ALB and NLB example](examples/complete) - Creates Application and Network Load Balancers with various configurations

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.0 |
| aws | >= 4.0 |

## Providers

| Name | Version |
|------|---------|
| aws | >= 4.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| aws_lb.this | resource |
| aws_lb_listener.this | resource |
| aws_lb_listener_rule.this | resource |
| aws_lb_target_group.this | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| create | Determines whether resources will be created | `bool` | `true` | no |
| name | The name of the LB. This name must be unique within your AWS account | `string` | n/a | yes |
| use_name_prefix | Determines whether to use `name` as is or create a unique name beginning with the `name` as the prefix | `bool` | `true` | no |
| load_balancer_type | The type of load balancer to create. Possible values are application, gateway, or network | `string` | `"application"` | no |
| internal | Determines if the load balancer is internal or externally facing | `bool` | `false` | no |
| security_groups | A list of security group IDs to assign to the LB | `list(string)` | `[]` | no |
| subnets | A list of subnet IDs to attach to the LB | `list(string)` | `[]` | no |
| subnet_mappings | A list of subnet mapping blocks describing subnets to attach to network load balancer | `list(object)` | `[]` | no |
| vpc_id | VPC id where the load balancer and other resources will be deployed | `string` | `null` | no |
| access_logs | Map containing access logging configuration for load balancer | `map(string)` | `{}` | no |
| target_groups | Map of target group configurations to create | `any` | `{}` | no |
| listeners | Map of listener configurations to create | `any` | `{}` | no |
| listener_rules | Map of listener rules to create | `any` | `{}` | no |
| tags | A map of tags to add to all resources | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| id | The ID and ARN of the load balancer we created |
| arn | The ARN of the load balancer we created |
| arn_suffix | ARN suffix of our load balancer - can be used with CloudWatch |
| dns_name | The DNS name of the load balancer |
| zone_id | The zone_id of the load balancer to assist with creating DNS records |
| listeners | Map of listeners created and their attributes |
| listener_rules | Map of listener rules created and their attributes |
| target_groups | Map of target groups created and their attributes |

## License

MIT Licensed. See LICENSE for full details.

## Maintainers

This module is maintained by [Senora.dev](https://senora.dev). 