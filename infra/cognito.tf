# ------------------------------------------------------
# Cognito User Pool — email-based sign-up/sign-in
# ------------------------------------------------------

resource "aws_cognito_user_pool" "main" {
  name = "${var.project}-${var.environment}"

  # Sign-in: email IS the username (no separate username field).
  username_attributes      = ["email"]
  auto_verified_attributes = ["email"]

  password_policy {
    minimum_length                   = 8
    require_lowercase                = true
    require_numbers                  = true
    require_symbols                  = false
    require_uppercase                = true
    temporary_password_validity_days = 7
  }

  # Self-service sign-up.
  admin_create_user_config {
    allow_admin_create_user_only = false
  }

  # Custom attribute for subscription tier.
  schema {
    attribute_data_type      = "String"
    name                     = "plan_tier"
    mutable                  = true
    required                 = false
    developer_only_attribute = false

    string_attribute_constraints {
      min_length = 1
      max_length = 20
    }
  }

  account_recovery_setting {
    recovery_mechanism {
      name     = "verified_email"
      priority = 1
    }
  }

  # No MFA for MVP.
  mfa_configuration = "OFF"
}

# ------------------------------------------------------
# App Client — mobile app (no client secret, SRP auth)
# ------------------------------------------------------

resource "aws_cognito_user_pool_client" "app" {
  name         = "${var.project}-app-${var.environment}"
  user_pool_id = aws_cognito_user_pool.main.id

  # No client secret — required for mobile/SPA apps.
  generate_secret = false

  # Auth flows for mobile.
  explicit_auth_flows = [
    "ALLOW_USER_SRP_AUTH",
    "ALLOW_REFRESH_TOKEN_AUTH",
    "ALLOW_USER_PASSWORD_AUTH",
  ]

  # Token validity.
  access_token_validity  = 1  # hours
  id_token_validity      = 1  # hours
  refresh_token_validity = 30 # days

  token_validity_units {
    access_token  = "hours"
    id_token      = "hours"
    refresh_token = "days"
  }

  # OAuth2 callback URLs for hosted UI flow.
  callback_urls = ["alpha://auth/callback"]
  logout_urls   = ["alpha://auth/signout"]

  allowed_oauth_flows                  = ["code"]
  allowed_oauth_flows_user_pool_client = true
  allowed_oauth_scopes                 = ["openid", "email"]
  supported_identity_providers         = ["COGNITO"]

  # Read/write custom attributes.
  read_attributes  = ["email", "custom:plan_tier"]
  write_attributes = ["email", "custom:plan_tier"]

  # Prevent user-existence errors from leaking info.
  prevent_user_existence_errors = "ENABLED"
}

# ------------------------------------------------------
# Cognito Domain — hosted UI for MVP sign-in
# ------------------------------------------------------

resource "aws_cognito_user_pool_domain" "main" {
  domain       = "${var.project}-${var.environment}-${data.aws_caller_identity.current.account_id}"
  user_pool_id = aws_cognito_user_pool.main.id
}
