# ------------------------------------------------------
# Bastion — minimal EC2 for SSH access to private VPC
#
# Standalone config. Reads VPC and RDS SG from the main
# Terraform state via remote state data source.
#
# Usage:
#   cd infra/bastion
#   terraform init
#   terraform apply        # spin up
#   terraform destroy      # tear down when done
# ------------------------------------------------------

terraform {
  required_version = ">= 1.5"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    bucket         = "alpha-terraform-state-773469078444"
    key            = "alpha/bastion/terraform.tfstate"
    region         = "us-west-2"
    dynamodb_table = "alpha-terraform-locks"
    encrypt        = true
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = "alpha"
      Environment = var.environment
      ManagedBy   = "terraform"
    }
  }
}

variable "aws_region" {
  default = "us-west-2"
}

variable "environment" {
  default = "dev"
}

variable "project" {
  default = "alpha"
}

# ---- Read VPC + RDS SG from main state ----

data "terraform_remote_state" "main" {
  backend = "s3"
  config = {
    bucket = "alpha-terraform-state-773469078444"
    key    = "alpha/terraform.tfstate"
    region = "us-west-2"
  }
}

# The main state doesn't export VPC/SG IDs yet, so look them up
# by tag instead. This avoids coupling to output changes.
data "aws_vpc" "main" {
  filter {
    name   = "tag:Name"
    values = ["${var.project}-${var.environment}"]
  }
}

data "aws_security_group" "rds" {
  filter {
    name   = "tag:Name"
    values = ["${var.project}-rds-${var.environment}"]
  }
}

# ---- Bastion resources ----

resource "aws_key_pair" "bastion" {
  key_name   = "${var.project}-bastion-${var.environment}"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDfvyBFgwcE9PN3P9tw6eRMa22NToLTiCTj6BlfGybetj2N/irO0Jjn0GVrG2Y6rRTXBcIcSVmBFQ3yR9XJ8IilOSxzByUMhV1letuOCSp8dWt/yDr7fynzeRuk4XQpW0UY7978DSm8rYhrLSOvG1tgr5p8NUhSSBPZDEO/gecobd5bwSBfITCIWX43AC1JgDDZLuTh0bEWWrmLFNKLXS0DtjqIsJWiugRuQ6MrIzHIUrxtKwIC9ykIdxJTaYVBDUOPQ1yiDhrbsSaFl95pbgVh8HwQo8yZavqo0w0S6J7dyUzi8U2F6gh4enc4aMHkuH4oYGlZD1iHbmvEG0v33s38YKMtHCH7NYxe8Om78LRR6axXlzxjiu98+IJGQ17GBSQKWSl8ulKd30zuO1w3beDQdpEt+Vi5K6kFriP6lo6L7lxeDis1finNKVdjYYv3KYaMPIrG/NnAE/j51792lQwP8+N0PzELdPmeUCeGzJlHkB/wkbrYRdhwWWsUOYgrEGs= alastair@vger.deep13.lol"
}

resource "aws_subnet" "public" {
  vpc_id                  = data.aws_vpc.main.id
  cidr_block              = "10.0.10.0/24"
  availability_zone       = "${var.aws_region}a"
  map_public_ip_on_launch = true

  tags = { Name = "${var.project}-public" }
}

resource "aws_internet_gateway" "main" {
  vpc_id = data.aws_vpc.main.id

  tags = { Name = "${var.project}-bastion-igw" }
}

resource "aws_route_table" "public" {
  vpc_id = data.aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = { Name = "${var.project}-public" }
}

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

resource "aws_security_group" "bastion" {
  name        = "${var.project}-bastion-${var.environment}"
  description = "Bastion SSH access"
  vpc_id      = data.aws_vpc.main.id

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${var.project}-bastion-${var.environment}" }
}

resource "aws_security_group_rule" "rds_from_bastion" {
  type                     = "ingress"
  from_port                = 5432
  to_port                  = 5432
  protocol                 = "tcp"
  security_group_id        = data.aws_security_group.rds.id
  source_security_group_id = aws_security_group.bastion.id
  description              = "Postgres from bastion"
}

data "aws_ami" "al2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-arm64"]
  }

  filter {
    name   = "architecture"
    values = ["arm64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_instance" "bastion" {
  ami                    = data.aws_ami.al2023.id
  instance_type          = "t4g.nano"
  key_name               = aws_key_pair.bastion.key_name
  subnet_id              = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.bastion.id]

  root_block_device {
    volume_size = 30
    volume_type = "gp3"
    encrypted   = true
  }

  user_data = <<-BASH
    #!/bin/bash
    dnf install -y postgresql16
  BASH

  tags = { Name = "${var.project}-bastion-${var.environment}" }
}

output "bastion_public_ip" {
  description = "Bastion public IP — ssh ec2-user@<ip>"
  value       = aws_instance.bastion.public_ip
}

output "ssh_command" {
  description = "SSH command to connect"
  value       = "ssh ec2-user@${aws_instance.bastion.public_ip}"
}
