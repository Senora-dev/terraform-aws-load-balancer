# Complete Application Load Balancer (ALB) Example

This example demonstrates a complete setup of an Application Load Balancer (ALB) with various advanced features and configurations.

## Features Demonstrated

- VPC with public and private subnets across multiple availability zones
- Internet Gateway and NAT Gateway for internet connectivity
- Application Load Balancer with:
  - HTTP to HTTPS redirection
  - Multiple target groups with weighted routing
  - Path-based routing rules
  - SSL/TLS termination
  - Access logging to S3
  - Cross-zone load balancing
  - HTTP/2 support
  - Deletion protection
  - Stickiness configuration
- Security groups for ALB and backend instances
- Self-signed SSL certificate for HTTPS
- S3 bucket for ALB access logs

## Usage

To run this example you need to execute:

```bash
$ terraform init
$ terraform plan
$ terraform apply
```

Note that this example may create resources which cost money. Run `terraform destroy` when you don't need these resources.

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.0 |
| aws | >= 4.0 |

## Providers

| Name | Version |
|------|---------|
| aws | >= 4.0 |
| tls | >= 3.0 |

## Resources Created

### VPC and Networking
- VPC with DNS support
- Internet Gateway
- Public and private subnets in 2 availability zones
- NAT Gateway with Elastic IP
- Route tables for public and private subnets

### Security
- Security group for ALB (allows HTTP/HTTPS from anywhere)
- Security group for backend instances (allows traffic from ALB)
- Self-signed SSL certificate for HTTPS listeners

### Load Balancer
- Application Load Balancer
- Target groups for different services
- HTTP listener with redirect to HTTPS
- HTTPS listener with:
  - SSL termination
  - Path-based routing
  - Weighted target group routing

### Storage
- S3 bucket for ALB access logs
- S3 bucket policy for ALB logging

## Outputs

| Name | Description |
|------|-------------|
| vpc_id | The ID of the VPC |
| public_subnet_ids | List of IDs of public subnets |
| private_subnet_ids | List of IDs of private subnets |
| alb_security_group_id | The ID of the ALB security group |
| backend_security_group_id | The ID of the backend security group |
| alb_id | The ID of the load balancer |
| alb_arn | The ARN of the load balancer |
| alb_dns_name | The DNS name of the load balancer |
| alb_zone_id | The zone_id of the load balancer |
| target_group_arns | ARNs of the target groups |
| target_group_names | Names of the target groups |
| http_listener_arn | The ARN of the HTTP listener |
| https_listener_arn | The ARN of the HTTPS listener |
| log_bucket_id | The ID of the S3 bucket for ALB access logs |
| log_bucket_arn | The ARN of the S3 bucket for ALB access logs |
| certificate_arn | The ARN of the certificate |

## Notes

1. This example uses a self-signed certificate for HTTPS. In a production environment, you should use a properly signed certificate from a trusted CA.
2. The example enables deletion protection for the ALB. You'll need to disable it before destroying the infrastructure.
3. The S3 bucket for access logs has force_destroy enabled for example purposes. In production, you might want to disable this.
4. The example creates resources across multiple availability zones for high availability.

## Related Examples

- [Basic ALB Example](../basic)
- [Network Load Balancer Example](../nlb) 