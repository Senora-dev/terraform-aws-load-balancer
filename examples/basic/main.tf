provider "aws" {
  region = "us-west-2"
}

# Create a VPC for the example
resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "example-vpc"
  }
}

# Create an internet gateway
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "example-igw"
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
    Name = "example-public-rt"
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
    Name = "public-${count.index + 1}"
  }
}

# Associate public subnets with public route table
resource "aws_route_table_association" "public" {
  count          = 2
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# Create a security group for the ALB
resource "aws_security_group" "alb" {
  name        = "alb-sg"
  description = "Security group for ALB"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 80
    to_port     = 80
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
    Name = "alb-sg"
  }
}

# Create the ALB
module "alb" {
  source = "../../"

  name               = "alb"
  use_name_prefix    = true
  load_balancer_type = "application"
  internal           = false
  vpc_id            = aws_vpc.main.id
  subnets           = aws_subnet.public[*].id
  security_groups   = [aws_security_group.alb.id]

  target_groups = {
    main = {
      name        = "main"
      port        = 80
      protocol    = "HTTP"
      target_type = "instance"
      health_check = {
        enabled             = true
        interval           = 30
        path               = "/"
        port               = "traffic-port"
        healthy_threshold   = 3
        unhealthy_threshold = 3
        timeout            = 5
        protocol           = "HTTP"
        matcher            = "200-399"
      }
    }
  }

  listeners = {
    http = {
      port     = 80
      protocol = "HTTP"
      default_action = {
        type             = "forward"
        target_group_arn = module.alb.target_groups["main"].arn
      }
    }
  }

  tags = {
    Environment = "dev"
    Terraform   = "true"
  }
} 