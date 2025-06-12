# Basic Load Balancer Example

This example demonstrates how to use the Load Balancer module in its simplest form to create an Application Load Balancer (ALB).

## Usage

To run this example you need to execute:

```bash
$ terraform init
$ terraform plan
$ terraform apply
```

Note that this example may create resources which cost money. Run `terraform destroy` when you don't need these resources anymore.

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.0 |
| aws | >= 4.0 |

## Providers

| Name | Version |
|------|---------|
| aws | >= 4.0 |

## Resources Created

- VPC with CIDR block 10.0.0.0/16
- 2 public subnets in different availability zones
- Security group for the ALB
  - Allows inbound HTTP (port 80)
  - Allows all outbound traffic
- Application Load Balancer
  - Single target group for HTTP traffic
  - Basic health check configuration
  - HTTP listener on port 80

## Outputs

| Name | Description |
|------|-------------|
| vpc_id | The ID of the VPC |
| alb_dns_name | The DNS name of the load balancer |
| target_group_arn | The ARN of the target group |
| security_group_id | The ID of the security group | 