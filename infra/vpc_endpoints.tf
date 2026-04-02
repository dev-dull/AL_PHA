# ------------------------------------------------------
# VPC Endpoints — allow Lambda to reach AWS services
# from private subnets without a NAT gateway.
# ------------------------------------------------------

resource "aws_security_group" "vpc_endpoints" {
  name        = "${var.project}-vpce-${var.environment}"
  description = "VPC endpoint access"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "HTTPS from Lambda"
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    security_groups = [aws_security_group.lambda.id]
  }

  tags = { Name = "${var.project}-vpce-${var.environment}" }
}

resource "aws_vpc_endpoint" "secretsmanager" {
  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.${var.aws_region}.secretsmanager"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true

  subnet_ids         = [aws_subnet.private_a.id, aws_subnet.private_b.id]
  security_group_ids = [aws_security_group.vpc_endpoints.id]

  tags = { Name = "${var.project}-secretsmanager-${var.environment}" }
}
