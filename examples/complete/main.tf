provider "aws" {
  region = "us-west-2"
}

locals {
  name = "alb"
}

# Create a VPC for the example
resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "complete-${local.name}-vpc"
  }
}

# Create an internet gateway
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${local.name}-igw"
  }
}

# Create public route table
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name = "${local.name}-public-rt"
  }
}

# Create public subnets
resource "aws_subnet" "public" {
  count             = 2
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.${count.index + 1}.0/24"
  availability_zone = "us-west-2${count.index == 0 ? "a" : "b"}"
  
  # Required for public subnets
  map_public_ip_on_launch = true

  tags = {
    Name = "${local.name}-public-${count.index + 1}"
  }
}

# Associate public subnets with public route table
resource "aws_route_table_association" "public" {
  count          = 2
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# Create private subnets
resource "aws_subnet" "private" {
  count             = 2
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.${count.index + 10}.0/24"
  availability_zone = "us-west-2${count.index == 0 ? "a" : "b"}"

  tags = {
    Name = "${local.name}-private-${count.index + 1}"
  }
}

# Create security groups
resource "aws_security_group" "alb" {
  name        = "${local.name}-alb-sg"
  description = "Security group for ALB"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "HTTP from anywhere"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS from anywhere"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${local.name}-alb-sg"
  }
}

resource "aws_security_group" "backend" {
  name        = "${local.name}-backend-sg"
  description = "Security group for backend instances"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "HTTP from ALB"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${local.name}-backend-sg"
  }
}

# Create S3 bucket for access logs
resource "aws_s3_bucket" "logs" {
  bucket_prefix = "${local.name}-logs-"
  force_destroy = true
}

resource "aws_s3_bucket_policy" "logs" {
  bucket = aws_s3_bucket.logs.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_elb_service_account.main.id}:root"
        }
        Action = "s3:PutObject"
        Resource = "${aws_s3_bucket.logs.arn}/*"
      }
    ]
  })
}

# Get the AWS account ID for the ALB service account
data "aws_elb_service_account" "main" {}

# Create the ALB
module "alb" {
  source = "../../"

  name               = local.name
  use_name_prefix    = true
  load_balancer_type = "application"
  internal           = false
  vpc_id            = aws_vpc.main.id
  subnets           = aws_subnet.public[*].id
  security_groups   = [aws_security_group.alb.id]

  # Enable access logs
  access_logs = {
    bucket  = aws_s3_bucket.logs.id
    prefix  = "alb-logs"
    enabled = true
  }

  # Enable HTTP/2
  enable_http2 = true

  # Enable deletion protection
  enable_deletion_protection = false

  # Enable cross-zone load balancing
  enable_cross_zone_load_balancing = true

  target_groups = {
    main = {
      name        = "main"
      port        = 80
      protocol    = "HTTP"
      target_type = "instance"
      
      health_check = {
        enabled             = true
        interval           = 30
        path               = "/health"
        port               = "traffic-port"
        healthy_threshold   = 3
        unhealthy_threshold = 3
        timeout            = 5
        protocol           = "HTTP"
        matcher            = "200-399"
      }

      stickiness = {
        enabled         = true
        type           = "lb_cookie"
        cookie_duration = 86400
      }
    }
    secondary = {
      name        = "secondary"
      port        = 80
      protocol    = "HTTP"
      target_type = "instance"
      
      health_check = {
        enabled             = true
        interval           = 30
        path               = "/health"
        port               = "traffic-port"
        healthy_threshold   = 3
        unhealthy_threshold = 3
        timeout            = 5
        protocol           = "HTTP"
        matcher            = "200-399"
      }
    }
  }

  # HTTP Listener only - no HTTPS for now
  listeners = {
    http = {
      port     = 80
      protocol = "HTTP"
      
      default_action = {
        type = "forward"
        forward = {
          target_groups = [
            {
              arn    = module.alb.target_groups["main"].arn
              weight = 80
            },
            {
              arn    = module.alb.target_groups["secondary"].arn
              weight = 20
            }
          ]
          stickiness = {
            enabled  = true
            duration = 600
          }
        }
      }
    }
  }

  # Listener rules for path-based routing
  listener_rules = {
    api = {
      listener_key = "http"
      priority     = 100

      conditions = [
        {
          path_pattern = {
            values = ["/api/*"]
          }
        }
      ]

      action = {
        type             = "forward"
        target_group_arn = module.alb.target_groups["main"].arn
      }
    }

    static = {
      listener_key = "http"
      priority     = 200

      conditions = [
        {
          path_pattern = {
            values = ["/static/*"]
          }
        }
      ]

      action = {
        type             = "forward"
        target_group_arn = module.alb.target_groups["secondary"].arn
      }
    }
  }

  tags = {
    Environment = "dev"
    Terraform   = "true"
    Example     = "complete"
  }
}

# We'll add HTTPS support later once we resolve the certificate issues
# For now, commenting out the certificate resources
/*
resource "tls_private_key" "this" {
  algorithm = "RSA"
}

resource "tls_self_signed_cert" "this" {
  private_key_pem = tls_private_key.this.private_key_pem

  subject {
    common_name  = "example.com"
    organization = "Example Organization"
  }

  validity_period_hours = 24
  set_subject_key_id   = true
  is_ca_certificate    = false

  allowed_uses = [
    "key_encipherment",
    "digital_signature",
    "server_auth",
  ]
}

resource "aws_acm_certificate" "this" {
  private_key      = tls_private_key.this.private_key_pem
  certificate_body = tls_self_signed_cert.this.cert_pem

  lifecycle {
    create_before_destroy = true
  }
}
*/ 

# Create private route table
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${local.name}-private-rt"
  }
}

# Associate private subnets with private route table
resource "aws_route_table_association" "private" {
  count          = 2
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private.id
} 