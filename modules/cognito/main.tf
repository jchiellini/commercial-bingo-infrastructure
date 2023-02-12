#   ____             _
#  |  _ \ ___   ___ | |
#  | |_) / _ \ / _ \| |
#  |  __/ (_) | (_) | |
#  |_|   \___/ \___/|_|

resource "aws_cognito_user_pool" "pool" {
  name                     = "${var.environment}-${var.app}"
  auto_verified_attributes = ["email"]
  username_attributes      = ["email"]
  mfa_configuration        = "OFF"


  admin_create_user_config {
    allow_admin_create_user_only = true
  }

  password_policy {
    minimum_length                   = 8
    require_lowercase                = true
    require_numbers                  = true
    require_symbols                  = true
    require_uppercase                = true
    temporary_password_validity_days = 7
  }

  schema {
    attribute_data_type      = "String"
    developer_only_attribute = false
    mutable                  = true
    name                     = "given_name"
    required                 = true

    string_attribute_constraints {
      max_length = "2048"
      min_length = "0"
    }
  }

  schema {
    attribute_data_type      = "String"
    developer_only_attribute = false
    mutable                  = true
    name                     = "name"
    required                 = true

    string_attribute_constraints {
      max_length = "2048"
      min_length = "0"
    }
  }

  schema {
    attribute_data_type      = "String"
    developer_only_attribute = false
    mutable                  = true
    name                     = "employee_id"
    required                 = false

    string_attribute_constraints {
      max_length = "2048"
      min_length = "0"
    }
  }

  account_recovery_setting {
    recovery_mechanism {
      name     = "verified_email"
      priority = 1
    }
  }

  tags = {
    Name        = "${var.environment}-${var.app} Cognito Pool"
    CostCenter  = var.app
    Environment = var.environment
  }
}

#    ____
#   / ___|_ __ ___  _   _ _ __  ___
#  | |  _| '__/ _ \| | | | '_ \/ __|
#  | |_| | | | (_) | |_| | |_) \__ \
#   \____|_|  \___/ \__,_| .__/|___/
#                        |_|

resource "aws_cognito_user_group" "full_access_group" {
  name         = "FULL_ACCESS"
  user_pool_id = aws_cognito_user_pool.pool.id
  description  = "Full Access role"
}

resource "aws_cognito_user_group" "field_access_group" {
  name         = "FIELD"
  user_pool_id = aws_cognito_user_pool.pool.id
  description  = "Field Access role"
}

#   ____
#  / ___|  ___ _ ____   _____ _ __
#  \___ \ / _ \ '__\ \ / / _ \ '__|
#   ___) |  __/ |   \ V /  __/ |
#  |____/ \___|_|    \_/ \___|_|

resource "aws_cognito_resource_server" "resource_client" {
  identifier   = var.domain
  name         = "Client"
  user_pool_id = aws_cognito_user_pool.pool.id
  scope {
    scope_name        = "login"
    scope_description = "Login"
  }
}

#      _                   ____ _ _            _
#     / \   _ __  _ __    / ___| (_) ___ _ __ | |_
#    / _ \ | '_ \| '_ \  | |   | | |/ _ \ '_ \| __|
#   / ___ \| |_) | |_) | | |___| | |  __/ | | | |_
#  /_/   \_\ .__/| .__/   \____|_|_|\___|_| |_|\__|
#          |_|   |_|

resource "aws_cognito_user_pool_client" "client" {
  name                                 = "Client"
  user_pool_id                         = aws_cognito_user_pool.pool.id
  allowed_oauth_flows                  = []
  allowed_oauth_flows_user_pool_client = false
  allowed_oauth_scopes                 = []
  explicit_auth_flows = [
    "ALLOW_ADMIN_USER_PASSWORD_AUTH",
    "ALLOW_CUSTOM_AUTH",
    "ALLOW_USER_PASSWORD_AUTH",
    "ALLOW_USER_SRP_AUTH",
    "ALLOW_REFRESH_TOKEN_AUTH"
  ]
  generate_secret        = false
  logout_urls            = []
  access_token_validity  = 1
  id_token_validity      = 1
  refresh_token_validity = 60
  token_validity_units {
    access_token  = "hours"
    id_token      = "hours"
    refresh_token = "days"
  }
}
