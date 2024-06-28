variable "rotation_function" {
  type        = any
  description = "Map for SecretsManager rotation function"

  default = {
    # https://github.com/aws-samples/aws-secrets-manager-rotation-lambdas/blob/master/SecretsManagerRDSMySQLRotationSingleUser/lambda_function.py
    function_name = "SecretsManager-rotation"
    runtime       = "python3.9"

    # Access to secretsmanager and RDS is required
    subnet_ids         = ["subnet-06fab1b614360aac4", "subnet-0c1c2c8b22c72a201"]
    security_group_ids = ["sg-085666c194cecea0a"]
  }
}
