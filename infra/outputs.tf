output "cognito_user_pool_id" {
  description = "Cognito User Pool ID"
  value       = aws_cognito_user_pool.main.id
}

output "cognito_app_client_id" {
  description = "Cognito App Client ID (for mobile app)"
  value       = aws_cognito_user_pool_client.app.id
}

output "cognito_domain" {
  description = "Cognito hosted UI domain"
  value       = "https://${aws_cognito_user_pool_domain.main.domain}.auth.${var.aws_region}.amazoncognito.com"
}

output "api_url" {
  description = "API Gateway base URL"
  value       = aws_apigatewayv2_api.main.api_endpoint
}

output "rds_endpoint" {
  description = "RDS Postgres endpoint (private)"
  value       = aws_db_instance.main.endpoint
  sensitive   = true
}

output "s3_migration_bucket" {
  description = "S3 bucket for migration transfers"
  value       = aws_s3_bucket.migrations.id
}

output "lambda_function_names" {
  description = "Lambda function names"
  value = {
    for k, v in aws_lambda_function.functions : k => v.function_name
  }
}
