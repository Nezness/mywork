#-------------------------
# IAM role
#-------------------------
resource "aws_iam_role" "Lambda_role_s3_to_textract" {
  name               = "${var.project}-${var.environment}-lambda-s3-to-textract"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json
}

resource "aws_iam_role" "Lambda_role_to_s3" {
  name               = "${var.project}-${var.environment}-lambda-to-s3"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json
}

resource "aws_iam_role" "Lambda_role_get_dynamodb" {
  name               = "${var.project}-${var.environment}-lambda-get-dynamodb"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json
}

resource "aws_iam_role" "Lambda_role_delete" {
  name               = "${var.project}-${var.environment}-lambda-delete"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json
}

#-------------------------
# Assume role policy // Who can use this
#-------------------------
data "aws_iam_policy_document" "lambda_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

#-------------------------
# Permissions Policy // What can this do
#-------------------------
data "aws_iam_policy_document" "lambda_permissions_s3_to_textract" {
  statement {
    effect = "Allow"
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "bedrock:InvokeModel",
      "aws-marketplace:ViewSubscriptions",
      "aws-marketplace:Subscribe",
      "aws-marketplace:Unsubscribe",
      "sqs:ReceiveMessage",
      "sqs:DeleteMessage",
      "sqs:GetQueueAttributes"
    ]
    resources = ["*"]
  }
  statement {
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:ListBucket",
      "s3:DeleteObject"
    ]
    resources = [
      aws_s3_bucket.s3_static_bucket.arn,
      "${aws_s3_bucket.s3_static_bucket.arn}/*"
    ]
  }

  statement {
    effect = "Allow"
    actions = [
      "dynamodb:PutItem",
      "dynamodb:GetItem",
      "dynamodb:UpdateItem",
      "dynamodb:Scan",
      "dynamodb:Query"
    ]
    resources = [
      aws_dynamodb_table.receipts.arn,
      aws_dynamodb_table.okan_usage.arn
    ]
  }
}

data "aws_iam_policy_document" "lambda_permissions_to_s3" {
  # 1. S3へのPutObject (署名付きURL発行のために必要)
  statement {
    effect  = "Allow"
    actions = ["s3:PutObject"]
    resources = [
      "${aws_s3_bucket.s3_static_bucket.arn}/*"
    ]
  }

  # 2. ログ出力 (必須)
  statement {
    effect = "Allow"
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    resources = ["*"]
  }

  # 3. DynamoDBへのアクセス (回数制限チェックに必須)
  statement {
    effect = "Allow"
    actions = [
      "dynamodb:Scan",
      "dynamodb:Query",
      "dynamodb:GetItem",
      "dynamodb:UpdateItem",
      "dynamodb:PutItem"
    ]
    resources = [
      aws_dynamodb_table.receipts.arn,
      aws_dynamodb_table.okan_usage.arn
    ]
  }
}

data "aws_iam_policy_document" "lambda_permissions_get_dynamodb" {
  statement {
    effect = "Allow"
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    resources = ["*"]
  }

  statement {
    effect = "Allow"
    actions = [
      "dynamodb:Scan",
      "dynamodb:Query",
      "dynamodb:GetItem"
    ]
    resources = [aws_dynamodb_table.receipts.arn]
  }
}

data "aws_iam_policy_document" "lambda_permission_delete" {
  statement {
    effect = "Allow"
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    resources = ["*"]
  }

  statement {
    effect = "Allow"
    actions = [
      "dynamodb:GetItem",
      "dynamodb:DeleteItem",
      "dynamodb:BatchWriteItem",
      "dynamodb:Query",
      "s3:ListBucket",
      "s3:DeleteObject",
      "cognito-idp:AdminDeleteUser"
    ]
    resources = ["*"]
  }
}
#-------------------------
# Other
#-------------------------
resource "aws_iam_policy" "lambda_policy_s3_to_textract" {
  name   = "${var.project}-${var.environment}-lambda-policy-s3-to-textract"
  policy = data.aws_iam_policy_document.lambda_permissions_s3_to_textract.json
}

resource "aws_iam_role_policy_attachment" "lambda_policy_attachment_s3_to_textract" {
  role       = aws_iam_role.Lambda_role_s3_to_textract.name
  policy_arn = aws_iam_policy.lambda_policy_s3_to_textract.arn
}

resource "aws_iam_policy" "lambda_policy_to_s3" {
  name   = "${var.project}-${var.environment}-lambda-policy-to-s3"
  policy = data.aws_iam_policy_document.lambda_permissions_to_s3.json
}

resource "aws_iam_role_policy_attachment" "lambda_policy_attachment_to_s3" {
  role       = aws_iam_role.Lambda_role_to_s3.name
  policy_arn = aws_iam_policy.lambda_policy_to_s3.arn
}

resource "aws_iam_policy" "lambda_policy_get_dynamodb" {
  name   = "${var.project}-${var.environment}-lambda-policy-get-dynamodb"
  policy = data.aws_iam_policy_document.lambda_permissions_get_dynamodb.json
}

resource "aws_iam_role_policy_attachment" "lambda_policy_attachment_get_dynamodb" {
  role       = aws_iam_role.Lambda_role_get_dynamodb.name
  policy_arn = aws_iam_policy.lambda_policy_get_dynamodb.arn
}

resource "aws_iam_policy" "lambda_policy_delete" {
  name   = "${var.project}-${var.environment}-lambda-policy-delete"
  policy = data.aws_iam_policy_document.lambda_permission_delete.json
}

resource "aws_iam_role_policy_attachment" "lambda_policy_attachment_delete" {
  role       = aws_iam_role.Lambda_role_delete.name
  policy_arn = aws_iam_policy.lambda_policy_delete.arn
}