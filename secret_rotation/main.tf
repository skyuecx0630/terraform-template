data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

resource "aws_lambda_function" "rotation_function" {
  function_name = var.rotation_function.function_name
  role          = aws_iam_role.rotation_function_role.arn
  handler       = "lambda_function.lambda_handler"

  runtime = var.rotation_function.runtime

  timeout = 30

  s3_bucket = "secrets-manager-rotation-apps-4a140910bc981d6b51d3a088522e3fe2"
  s3_key    = "SecretsManagerRDSMySQLRotationSingleUser/SecretsManagerRDSMySQLRotationSingleUser.zip"

  vpc_config {
    subnet_ids         = var.rotation_function.subnet_ids
    security_group_ids = var.rotation_function.security_group_ids
  }

  environment {
    variables = {
      "SECRETS_MANAGER_ENDPOINT"   = "https://secretsmanager.${data.aws_region.current.name}.amazonaws.com"
      "EXCLUDE_CHARACTERS"         = "/@\"'\\"
      "PASSWORD_LENGTH"            = "32"
      "EXCLUDE_NUMBERS"            = "false"
      "EXCLUDE_PUNCTUATION"        = "false"
      "EXCLUDE_UPPERCASE"          = "false"
      "EXCLUDE_LOWERCASE"          = "false"
      "REQUIRE_EACH_INCLUDED_TYPE" = "true"
    }
  }

  tags = {
    SecretsManagerLambda = "Rotation"
  }
}

resource "aws_iam_role" "rotation_function_role" {
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
  managed_policy_arns = [
    "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole",
    "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
  ]
  inline_policy {
    name = "${var.rotation_function.function_name}-policy"
    policy = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Effect = "Allow"
          Action = [
            "secretsmanager:DescribeSecret",
            "secretsmanager:GetSecretValue",
            "secretsmanager:PutSecretValue",
            "secretsmanager:UpdateSecretVersionStage",
            "secretsmanager:GetRandomPassword"
          ]
          Resource = "*"
        },
        {
          Effect = "Allow"
          Action = [
            "kms:Decrypt",
            "kms:DescribeKey",
            "kms:GenerateDataKey"
          ]
          Resource = "*"
        },
        {
          Effect = "Allow"
          Action = [
            "ec2:CreateNetworkInterface",
            "ec2:DeleteNetworkInterface",
            "ec2:DescribeNetworkInterfaces",
            "ec2:DetachNetworkInterface"
          ]
          Resource = "*"
        }
      ]
    })
  }
}

resource "aws_lambda_permission" "lambda_permission" {
  action         = "lambda:InvokeFunction"
  function_name  = aws_lambda_function.rotation_function.arn
  principal      = "secretsmanager.amazonaws.com"
  source_account = data.aws_caller_identity.current.account_id
}

# # Uncommenct only when runtime or package relevant errors occur
# resource "aws_lambda_runtime_management_config" "lambda_runtime_management_config" {
#   function_name     = aws_lambda_function.rotation_function.function_name
#   update_runtime_on = "Manual"

#   runtime_version_arn = "arn:aws:lambda:us-east-1::runtime:2745dd346f184b89561d5666019e2ee128f0975d3f033f2d7f23da717f177880"
# }
