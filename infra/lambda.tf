# ------------------------------------------------------
# Lambda Functions — sync + migration handlers
# ------------------------------------------------------

locals {
  lambda_runtime = "python3.12"
  lambda_handler = "handler.lambda_handler"

  # DB connection string passed to all Lambdas.
  lambda_env = {
    DB_SECRET_ARN = aws_secretsmanager_secret.db_password.arn
    DB_HOST       = aws_db_instance.main.address
    DB_PORT       = tostring(aws_db_instance.main.port)
    DB_NAME       = aws_db_instance.main.db_name
    S3_BUCKET     = aws_s3_bucket.migrations.id
    ENVIRONMENT   = var.environment
  }

  functions = {
    sync_push        = "Handles POST /sync/push"
    sync_pull        = "Handles POST /sync/pull"
    sync_status      = "Handles GET /sync/status"
    migrate_upload   = "Handles POST /migrate/upload"
    migrate_download = "Handles POST /migrate/download/{code}"
  }
}

# Stub zip — placeholder until real Lambda code is deployed.
data "archive_file" "lambda_stub" {
  type        = "zip"
  output_path = "${path.module}/.build/lambda_stub.zip"

  source {
    content  = <<-PYTHON
      def lambda_handler(event, context):
          return {
              "statusCode": 200,
              "body": '{"status": "stub"}'
          }
    PYTHON
    filename = "handler.py"
  }
}

resource "aws_lambda_function" "functions" {
  for_each = local.functions

  function_name = "${var.project}-${replace(each.key, "_", "-")}-${var.environment}"
  description   = each.value
  role          = aws_iam_role.lambda.arn

  runtime     = local.lambda_runtime
  handler     = local.lambda_handler
  memory_size = var.lambda_memory
  timeout     = var.lambda_timeout

  filename         = data.archive_file.lambda_stub.output_path
  source_code_hash = data.archive_file.lambda_stub.output_base64sha256

  environment {
    variables = local.lambda_env
  }

  vpc_config {
    subnet_ids         = [aws_subnet.private_a.id, aws_subnet.private_b.id]
    security_group_ids = [aws_security_group.lambda.id]
  }

  tags = { Function = each.key }
}
