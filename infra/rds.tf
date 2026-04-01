# ------------------------------------------------------
# RDS Postgres — cloud source of truth
# ------------------------------------------------------

# Auto-generated master password stored in Secrets Manager.
resource "aws_secretsmanager_secret" "db_password" {
  name                    = "${var.project}/${var.environment}/db-password"
  recovery_window_in_days = 0 # Allow immediate deletion in dev
}

resource "aws_secretsmanager_secret_version" "db_password" {
  secret_id = aws_secretsmanager_secret.db_password.id
  secret_string = jsonencode({
    username = "alpha_admin"
    password = random_password.db.result
  })
}

resource "random_password" "db" {
  length  = 32
  special = false # Avoid shell-escaping issues in connection strings
}

resource "aws_db_instance" "main" {
  identifier = "${var.project}-${var.environment}"

  engine         = "postgres"
  engine_version = "16"
  instance_class = var.db_instance_class

  allocated_storage     = var.db_allocated_storage
  max_allocated_storage = var.db_max_allocated_storage
  storage_type          = "gp3"
  storage_encrypted     = true

  db_name  = "alpha"
  username = "alpha_admin"
  password = random_password.db.result

  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.rds.id]
  publicly_accessible    = false
  multi_az               = false # Off for dev, on for prod

  backup_retention_period   = 7
  skip_final_snapshot       = var.environment == "dev"
  final_snapshot_identifier = var.environment == "dev" ? null : "${var.project}-${var.environment}-final"
  deletion_protection       = var.environment != "dev"

  performance_insights_enabled = false # Free tier doesn't include this on micro

  tags = { Name = "${var.project}-${var.environment}" }
}
