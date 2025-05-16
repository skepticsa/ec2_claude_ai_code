# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This repository contains Terraform infrastructure-as-code for deploying a secure AWS bastion host following the Well-Architected Framework principles. The infrastructure includes a VPC with public/private subnets, an EC2 bastion instance with enhanced security features, and comprehensive monitoring.

## Common Commands

### Terraform Operations
```bash
cd terraform

# Initialize Terraform
terraform init

# Validate configuration
terraform validate

# View planned changes
terraform plan

# Deploy infrastructure
terraform apply

# Destroy infrastructure
terraform destroy

# Format code
terraform fmt

# View outputs
terraform output

# View specific output
terraform output -raw ssh_command
terraform output -raw ssm_command
```

### SSH Access
```bash
# Connect to bastion using SSH key
ssh -i ../bastion-us-east-1.pem ubuntu@$(terraform output -raw bastion_public_ip)

# Connect using AWS Systems Manager Session Manager
aws ssm start-session --target $(terraform output -raw bastion_instance_id)
```

## Architecture and Structure

### Infrastructure Components
- **VPC**: Custom VPC (10.3.0.0/16) in us-east-1 with public/private subnets across 2 AZs
  - VPC ID: vpc-077ffa46d14760dd4
  - Public Subnets: 10.3.1.0/24, 10.3.2.0/24
  - Private Subnets: 10.3.10.0/24, 10.3.11.0/24
- **EC2 Instance**: t3.micro bastion host with Ubuntu 22.04 LTS, IMDSv2, encrypted EBS
  - Instance ID: i-0abe09204bf37a402
  - Public IP: 3.84.206.156
  - Private IP: 10.3.1.140
- **Security**: Restricted SSH access (x.y.w.z/32), IAM roles, VPC Flow Logs to S3
  - Security Group: sg-08236330645efb9a7
  - IAM Role: bastion-ec2-bastion-role
- **Monitoring**: CloudWatch logs, VPC Flow Logs, automated security updates
  - CloudWatch Log Group: /aws/ec2/bastion-ec2
  - VPC Flow Logs S3 Bucket: bastion-ec2-flow-logs-20250516162901387100000001

### File Organization
```
.
├── .gitignore             # Git ignore patterns
├── CLAUDE.md              # This guidance file
├── README.md              # Main documentation
├── bastion-us-east-1.pem  # SSH private key (gitignored)
├── network_diagram.svg    # Architecture diagram
└── terraform/
    ├── main.tf              # Core infrastructure configuration
    ├── variables.tf         # Input variable definitions  
    ├── terraform.tfvars     # Variable values with actual IPs (gitignored)
    ├── terraform.tfvars.dev # Development variables
    ├── outputs.tf           # Output definitions
    ├── providers.tf         # AWS provider configuration
    ├── vpc.tf              # VPC, subnets, route tables
    ├── ec2.tf              # EC2 instance, user data
    ├── security.tf         # Security groups, IAM, KMS
    └── user_data.sh        # Instance initialization
```

### Key Design Decisions
1. **No NAT Gateway**: Cost optimization (private subnets cannot reach internet)
2. **S3 for VPC Flow Logs**: More cost-effective than CloudWatch Logs
3. **IMDSv2 Required**: Enhanced security for instance metadata
4. **SSM Session Manager**: Alternative access method without SSH exposure
5. **Encrypted EBS**: KMS encryption for data at rest (Key ID: 57769034-1aba-4c76-93a7-22deb16b4625)

## Important Configuration

### Default SSH Access
The security group allows SSH only from IP: `x.y.w.z/32`  
To change this, modify `allowed_ssh_cidr` in `terraform.tfvars`

### SSH Key
Requires existing key pair named `bastion-us-east-1` in us-east-1 region

### Environment-Specific Variables
- `terraform.tfvars` - Production values (gitignored)
- `terraform.tfvars.dev` - Development environment values

### User Data Script
The EC2 instance runs `user_data.sh` on launch to:
- Update/upgrade Ubuntu packages
- Configure fail2ban for SSH protection
- Set up CloudWatch agent
- Enable automatic security updates

## Currently Deployed Infrastructure

- **VPC ID**: vpc-077ffa46d14760dd4
- **Instance ID**: i-0abe09204bf37a402
- **Public IP**: 3.84.206.156
- **SSH Command**: `ssh -i /path/to/bastion-us-east-1.pem ubuntu@3.84.206.156`
- **SSM Command**: `aws ssm start-session --target i-0abe09204bf37a402`

## Validation and Troubleshooting

### Before Deployment
1. Ensure AWS credentials are configured (`aws configure`)
2. Verify SSH key pair exists in target region
3. Check/modify `allowed_ssh_cidr` for your IP address

### Common Issues
- **Terraform state errors**: Use `terraform refresh` to sync state
- **VPC Flow Logs errors**: Check S3 bucket policy configuration
- **SSH connection failures**: Verify security group rules and your public IP
- **SSM Session failures**: Check IAM role permissions and internet connectivity

### Cost Considerations
- Estimated monthly cost: ~$11-15
- Main costs: EC2 t3.micro (~$8.40), EBS storage (~$1.60)
- VPC Flow Logs to S3: ~$0.10/month
- CloudWatch Logs (365-day retention): ~$0.50/month
- Minimize costs by stopping instance when not needed