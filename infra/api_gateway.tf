# ------------------------------------------------------
# API Gateway v2 (HTTP API) — sync + migration endpoints
# ------------------------------------------------------

resource "aws_apigatewayv2_api" "main" {
  name          = "${var.project}-api-${var.environment}"
  protocol_type = "HTTP"

  cors_configuration {
    allow_origins = ["*"]
    allow_methods = ["POST", "GET", "OPTIONS"]
    allow_headers = ["Authorization", "Content-Type"]
    max_age       = 3600
  }
}

# Cognito JWT authorizer.
resource "aws_apigatewayv2_authorizer" "cognito" {
  api_id          = aws_apigatewayv2_api.main.id
  name            = "cognito"
  authorizer_type = "JWT"

  identity_sources = ["$request.header.Authorization"]

  jwt_configuration {
    audience = [aws_cognito_user_pool_client.app.id]
    issuer   = "https://cognito-idp.${var.aws_region}.amazonaws.com/${aws_cognito_user_pool.main.id}"
  }
}

# Default stage with auto-deploy.
resource "aws_apigatewayv2_stage" "default" {
  api_id      = aws_apigatewayv2_api.main.id
  name        = "$default"
  auto_deploy = true

  default_route_settings {
    throttling_burst_limit = 100
    throttling_rate_limit  = 50
  }
}

# ---- Route + Integration definitions ----

locals {
  # Routes that require Cognito auth.
  authed_routes = {
    "POST /sync/push"  = "sync_push"
    "POST /sync/pull"  = "sync_pull"
    "GET /sync/status" = "sync_status"
  }

  # Routes that do NOT require auth (migration uses transfer codes).
  public_routes = {
    "POST /migrate/upload"          = "migrate_upload"
    "POST /migrate/download/{code}" = "migrate_download"
  }
}

# Lambda integrations (one per function).
resource "aws_apigatewayv2_integration" "functions" {
  for_each = local.functions

  api_id                 = aws_apigatewayv2_api.main.id
  integration_type       = "AWS_PROXY"
  integration_uri        = aws_lambda_function.functions[each.key].invoke_arn
  integration_method     = "POST"
  payload_format_version = "2.0"
}

# Authed routes.
resource "aws_apigatewayv2_route" "authed" {
  for_each = local.authed_routes

  api_id    = aws_apigatewayv2_api.main.id
  route_key = each.key
  target    = "integrations/${aws_apigatewayv2_integration.functions[each.value].id}"

  authorization_type = "JWT"
  authorizer_id      = aws_apigatewayv2_authorizer.cognito.id
}

# Public routes (migration — uses transfer codes, not JWT).
resource "aws_apigatewayv2_route" "public" {
  for_each = local.public_routes

  api_id    = aws_apigatewayv2_api.main.id
  route_key = each.key
  target    = "integrations/${aws_apigatewayv2_integration.functions[each.value].id}"
}

# Lambda permissions — allow API Gateway to invoke each function.
resource "aws_lambda_permission" "apigw" {
  for_each = local.functions

  statement_id  = "AllowAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.functions[each.key].function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.main.execution_arn}/*/*"
}
