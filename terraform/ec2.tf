# Data source for latest Ubuntu 22.04 LTS AMI
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# User data script for initial configuration
locals {
  user_data = templatefile("${path.module}/user_data.sh", {
    project_name = var.project_name
  })
}

# EC2 Instance
resource "aws_instance" "bastion" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.instance_type
  key_name               = var.ssh_key_name
  subnet_id              = aws_subnet.public[0].id
  vpc_security_group_ids = [aws_security_group.bastion.id]
  iam_instance_profile   = aws_iam_instance_profile.bastion.name
  monitoring             = true # Enable detailed monitoring for security compliance
  ebs_optimized          = true # Enable EBS optimization for better performance

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required" # IMDSv2
    http_put_response_hop_limit = 1
    instance_metadata_tags      = "enabled"
  }

  root_block_device {
    volume_type           = var.root_volume_type
    volume_size           = var.root_volume_size
    encrypted             = true
    kms_key_id            = aws_kms_key.ebs.arn
    delete_on_termination = true

    tags = {
      Name = "${var.project_name}-root-volume"
    }
  }

  user_data = local.user_data

  tags = {
    Name = "${var.project_name}-bastion"
    OS   = "Ubuntu-22.04-LTS"
  }

  lifecycle {
    create_before_destroy = true
  }
}

# CloudWatch Log Group for Instance Logs
resource "aws_cloudwatch_log_group" "bastion" {
  name              = "/aws/ec2/${var.project_name}"
  retention_in_days = 365 # Updated to 1 year for compliance

  tags = {
    Name = "${var.project_name}-logs"
  }
}