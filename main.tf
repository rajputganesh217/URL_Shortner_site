provider "aws" {
  region = "<your_region>"  # e.g., "us-east-2"
}

# DynamoDB Table for storing URLs
resource "aws_dynamodb_table" "url_shortener" {
  name         = "<your_dynamodb_table_name>"  # e.g., "url_shortner"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "short_id"

  attribute {
    name = "short_id"
    type = "S"
  }
}

# IAM Role for Lambda
resource "aws_iam_role" "lambda_role" {
  name = "<your_lambda_role_name>"  # e.g., "url_shortener_lambda_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

# IAM Policy for Lambda to Access DynamoDB
resource "aws_iam_policy" "lambda_dynamodb_policy" {
  name        = "<your_policy_name>"  # e.g., "lambda_dynamodb_policy"
  description = "Allow Lambda to access DynamoDB"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["dynamodb:PutItem", "dynamodb:GetItem"]
        Resource = aws_dynamodb_table.url_shortener.arn
      },
      {
        Effect   = "Allow"
        Action   = ["logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents"]
        Resource = "arn:aws:logs:*:*:*"
      }
    ]
  })
}

# Attach IAM Policy to Role
resource "aws_iam_role_policy_attachment" "lambda_dynamodb_attach" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.lambda_dynamodb_policy.arn
}

# Lambda Function
resource "aws_lambda_function" "url_shortener_lambda" {
  function_name = "<your_lambda_function_name>"  # e.g., "url_shortener"
  role          = aws_iam_role.lambda_role.arn
  handler       = "lambda_function.lambda_handler"
  runtime       = "python3.11"
  timeout       = 10

  filename         = "<your_lambda_zip_file>"  # e.g., "lambda_function.zip"
  source_code_hash = filebase64sha256("<your_lambda_zip_file>")

  environment {
    variables = {
      TABLE_NAME = aws_dynamodb_table.url_shortener.name
    }
  }
}

# API Gateway
resource "aws_apigatewayv2_api" "url_api" {
  name          = "<your_api_name>"  # e.g., "url_shortener_api"
  protocol_type = "HTTP"
}

resource "aws_apigatewayv2_stage" "default" {
  api_id      = aws_apigatewayv2_api.url_api.id
  name        = "$default"
  auto_deploy = true
}

resource "aws_apigatewayv2_integration" "lambda" {
  api_id           = aws_apigatewayv2_api.url_api.id
  integration_type = "AWS_PROXY"
  integration_uri  = aws_lambda_function.url_shortener_lambda.invoke_arn
}

resource "aws_apigatewayv2_route" "root" {
  api_id    = aws_apigatewayv2_api.url_api.id
  route_key = "POST /shorten"
  target    = "integrations/${aws_apigatewayv2_integration.lambda.id}"
}

resource "aws_lambda_permission" "api_gateway" {
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.url_shortener_lambda.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.url_api.execution_arn}/*/*"
}

# Optional: S3 Bucket for Frontend
# resource "aws_s3_bucket" "frontend_bucket" {
#   bucket = "<your_frontend_bucket_name>"
# }
#
# resource "aws_s3_bucket_website_configuration" "frontend_config" {
#   bucket = aws_s3_bucket.frontend_bucket.id
#
#   index_document {
#     suffix = "index.html"
#   }
# }

# Output API endpoint
output "api_endpoint" {
  value = aws_apigatewayv2_api.url_api.api_endpoint
}
