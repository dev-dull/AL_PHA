# ------------------------------------------------------
# Lambda Functions — sync + migration handlers
# ------------------------------------------------------

locals {
  lambda_runtime = "python3.12"
  lambda_src_dir = "${path.module}/../lambda"

  # DB connection string passed to all Lambdas.
  lambda_env = {
    DB_SECRET_ARN = aws_secretsmanager_secret.db_password.arn
    DB_HOST       = aws_db_instance.main.address
    DB_PORT       = tostring(aws_db_instance.main.port)
    DB_NAME       = aws_db_instance.main.db_name
    S3_BUCKET     = aws_s3_bucket.migrations.id
    ENVIRONMENT   = var.environment
  }

  # Maps function key → (handler module, description).
  functions = {
    sync_push        = { handler = "sync_push.lambda_handler", desc = "POST /sync/push" }
    sync_pull        = { handler = "sync_pull.lambda_handler", desc = "POST /sync/pull" }
    sync_status      = { handler = "sync_status.lambda_handler", desc = "GET /sync/status" }
    migrate_upload   = { handler = "migrate_upload.lambda_handler", desc = "POST /migrate/upload" }
    migrate_download = { handler = "migrate_download.lambda_handler", desc = "POST /migrate/download/{code}" }
  }
}

# Package all lambda source into a single zip. In production,
# the CI pipeline builds per-function zips with dependencies.
# For Terraform, this packages the source so `terraform apply`
# can create the functions without a separate build step.
# psycopg2 Lambda layer — built locally and uploaded.
# Rebuild with: pip install --platform manylinux2014_x86_64
#   --only-binary=:all: --python-version 3.12
#   --target /tmp/lambda-layer/python psycopg2-binary==2.9.9
resource "aws_lambda_layer_version" "psycopg2" {
  layer_name          = "${var.project}-psycopg2"
  filename            = "${path.module}/.build/psycopg2-layer.zip"
  compatible_runtimes = [local.lambda_runtime]
  source_code_hash    = filebase64sha256("${path.module}/.build/psycopg2-layer.zip")
}

data "archive_file" "lambda_package" {
  type        = "zip"
  source_dir  = local.lambda_src_dir
  output_path = "${path.module}/.build/lambda.zip"
  excludes    = ["__pycache__", "*.pyc", ".pytest_cache"]
}

resource "aws_lambda_function" "functions" {
  for_each = local.functions

  function_name = "${var.project}-${replace(each.key, "_", "-")}-${var.environment}"
  description   = each.value.desc
  role          = aws_iam_role.lambda.arn

  runtime     = local.lambda_runtime
  handler     = each.value.handler
  memory_size = var.lambda_memory
  timeout     = var.lambda_timeout

  filename         = data.archive_file.lambda_package.output_path
  source_code_hash = data.archive_file.lambda_package.output_base64sha256

  environment {
    variables = local.lambda_env
  }

  layers = [aws_lambda_layer_version.psycopg2.arn]

  vpc_config {
    subnet_ids         = [aws_subnet.private_a.id, aws_subnet.private_b.id]
    security_group_ids = [aws_security_group.lambda.id]
  }

  tags = { Function = each.key }
}
