#-------------------------
# Cognito
#-------------------------
resource "aws_cognito_user_pool" "****" { // Put your pool-name to ****.
  name                     = "****"
  username_attributes      = ["email"]
  auto_verified_attributes = ["email"]

  password_policy {
    minimum_length    = 8
    require_lowercase = true
    require_numbers   = true
    require_symbols   = false
    require_uppercase = false
  }

  verification_message_template {
    default_email_option = "CONFIRM_WITH_CODE"
  }
}

resource "aws_cognito_user_pool_client" "okan_client" {
  name         = "okan-app-client"
  user_pool_id = aws_cognito_user_pool.****.id

  generate_secret = false

  explicit_auth_flows = [
    "ALLOW_USER_PASSWORD_AUTH",
    "ALLOW_REFRESH_TOKEN_AUTH",
    "ALLOW_USER_SRP_AUTH"
  ]
}

output "cognito_user_pool_id" {
  value = aws_cognito_user_pool.****.id
}

output "cognito_client_id" {
  value = aws_cognito_user_pool_client.okan_client.id
}
