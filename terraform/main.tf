# Main configuration entry point
# This file orchestrates the deployment of the entire infrastructure

# Local values for common tags and naming
locals {
  common_tags = {
    Environment = var.environment
    Project     = var.project_name
    ManagedBy   = "Terraform"
  }

  # Cost allocation tags
  cost_tags = {
    CostCenter = "IT-Infrastructure"
    Owner      = "CloudOps"
  }

  all_tags = merge(local.common_tags, local.cost_tags)
}

# Data source to get current AWS account ID
data "aws_caller_identity" "current" {}

# Data source to get current region
data "aws_region" "current" {}

# S3 bucket for Terraform state (optional - for remote state)
# Uncomment and configure if you want to use remote state
/*
terraform {
  backend "s3" {
    bucket         = "your-terraform-state-bucket"
    key            = "bastion/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "terraform-state-lock"
  }
}
*/ 