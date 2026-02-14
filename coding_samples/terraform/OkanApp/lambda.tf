#-------------------------
# AWS Lambda function // Python 3.12
#-------------------------
## For sending receipt to Textract
data "archive_file" "lambda_s3_to_textract_zip" {
  type        = "zip"
  source_dir  = "${path.module}/src"
  output_path = "${path.module}/lambda_function_s3_to_textract.zip"
}

resource "aws_lambda_function" "s3_to_textract" {
  filename         = data.archive_file.lambda_s3_to_textract_zip.output_path // Path to zip
  function_name    = "${var.project}-${var.environment}-lambda-s3-to-textract"
  role             = aws_iam_role.Lambda_role_s3_to_textract.arn // Set IAMrole which can read s3 object
  handler          = "index.handler"                             // program-name.handler
  runtime          = "python3.12"
  source_code_hash = data.archive_file.lambda_s3_to_textract_zip.output_base64sha256
  timeout          = 60
}

## For Issuing presigned-url
data "archive_file" "lambda_to_s3_zip" {
  type        = "zip"
  source_dir  = "${path.module}/src"
  output_path = "${path.module}/lambda_function_to_s3.zip"
}

resource "aws_lambda_function" "to_s3" {
  filename         = data.archive_file.lambda_to_s3_zip.output_path
  function_name    = "${var.project}-${var.environment}-lambda-to-s3"
  role             = aws_iam_role.Lambda_role_to_s3.arn
  handler          = "request.handler"
  runtime          = "python3.12"
  source_code_hash = data.archive_file.lambda_to_s3_zip.output_base64sha256
  timeout          = 10

  environment {
    variables = {
      BUCKET_NAME = aws_s3_bucket_notification.s3_static_bucket.id
    }
  }
}

## Dynamodb to API Gateway
data "archive_file" "get_dynamodb_zip" {
  type        = "zip"
  source_file = "${path.module}/src/get.py"
  output_path = "${path.module}/lambda_function_get_dynamodb.zip"
}

resource "aws_lambda_function" "get_dynamodb" {
  filename         = data.archive_file.get_dynamodb_zip.output_path
  function_name    = "${var.project}-${var.environment}-get-dynamodb"
  role             = aws_iam_role.Lambda_role_get_dynamodb.arn
  handler          = "get.handler"
  runtime          = "python3.12"
  source_code_hash = data.archive_file.get_dynamodb_zip.output_base64sha256
  timeout          = 20

  environment {
    variables = {
      TABLE_NAME = aws_dynamodb_table.receipts.name
    }
  }
}

resource "aws_lambda_permission" "api_gw_invoke_get_dynamodb" {
  statement_id  = "AllowExecutionFromAPIGatewayGet"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.get_dynamodb.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.receipt_api.execution_arn}/*/*/receipts"
}

## For deleting
data "archive_file" "delete_receipt_zip" {
  type        = "zip"
  source_file = "${path.module}/src/delete.py"
  output_path = "${path.module}/lambda_function_delete.zip"
}

resource "aws_lambda_function" "delete_receipt" {
  filename         = data.archive_file.delete_receipt_zip.output_path
  function_name    = "${var.project}-${var.environment}-delete-receipt"
  role             = aws_iam_role.Lambda_role_delete.arn
  handler          = "delete.handler"
  runtime          = "python3.12"
  source_code_hash = data.archive_file.delete_receipt_zip.output_base64sha256

  environment {
    variables = {
      TABLE_NAME       = aws_dynamodb_table.receipts.name
      BUCKET_NAME      = aws_s3_bucket_notification.s3_static_bucket.id
      USAGE_TABLE_NAME = aws_dynamodb_table.okan_usage.name
      USER_POOL_ID     = aws_cognito_user_pool.okan_pool.id
    }
  }
}

resource "aws_apigatewayv2_integration" "delete_receipt_integration" {
  api_id           = aws_apigatewayv2_api.receipt_api.id
  integration_type = "AWS_PROXY"
  integration_uri  = aws_lambda_function.delete_receipt.invoke_arn
}

resource "aws_apigatewayv2_route" "delete_receipt_route" {
  api_id    = aws_apigatewayv2_api.receipt_api.id
  route_key = "DELETE /receipts"
  target    = "integrations/${aws_apigatewayv2_integration.delete_receipt_integration.id}"
}

resource "aws_lambda_permission" "api_gw_invoke_delete" {
  statement_id  = "AllowExecutionFromAPIGatewayDelete"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.delete_receipt.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.receipt_api.execution_arn}/*/*/receipts"
}

# タグ更新用Lambda
data "archive_file" "update_receipt_zip" {
  type        = "zip"
  source_file = "${path.module}/src/update.py"
  output_path = "${path.module}/lambda_function_update.zip"
}

resource "aws_lambda_function" "update_receipt" {
  filename         = data.archive_file.update_receipt_zip.output_path
  function_name    = "${var.project}-${var.environment}-lambda-update"
  role             = aws_iam_role.Lambda_role_s3_to_textract.arn
  handler          = "update.handler"
  source_code_hash = data.archive_file.update_receipt_zip.output_base64sha256
  runtime          = "python3.12"
  timeout          = 30

  environment {
    variables = {
      TABLE_NAME = aws_dynamodb_table.receipts.name
    }
  }
}

# API Gatewayからの起動許可
resource "aws_lambda_permission" "api_gw_invoke_update" {
  statement_id  = "AllowExecutionFromAPIGatewayUpdate"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.update_receipt.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.receipt_api.execution_arn}/*/*"
}