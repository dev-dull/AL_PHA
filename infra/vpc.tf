# ------------------------------------------------------
# VPC — private networking for RDS + Lambda
# ------------------------------------------------------

resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = { Name = "${var.project}-${var.environment}" }
}

# Two private subnets in different AZs (required for RDS subnet group).
resource "aws_subnet" "private_a" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "${var.aws_region}a"

  tags = { Name = "${var.project}-private-a" }
}

resource "aws_subnet" "private_b" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "${var.aws_region}b"

  tags = { Name = "${var.project}-private-b" }
}

# Security group for RDS — only Lambda can connect.
resource "aws_security_group" "rds" {
  name        = "${var.project}-rds-${var.environment}"
  description = "Allow Postgres from Lambda"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "Postgres from Lambda"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.lambda.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${var.project}-rds-${var.environment}" }
}

# Security group for Lambda — outbound to RDS + internet.
resource "aws_security_group" "lambda" {
  name        = "${var.project}-lambda-${var.environment}"
  description = "Lambda outbound access"
  vpc_id      = aws_vpc.main.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${var.project}-lambda-${var.environment}" }
}

# RDS subnet group.
resource "aws_db_subnet_group" "main" {
  name = "${var.project}-${var.environment}"
  subnet_ids = [
    aws_subnet.private_a.id,
    aws_subnet.private_b.id,
  ]

  tags = { Name = "${var.project}-${var.environment}" }
}
