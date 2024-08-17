variable "rotation_function" {
  type        = any
  description = "Map for SecretsManager rotation function"

  default = {
    # https://github.com/aws-samples/aws-secrets-manager-rotation-lambdas/blob/master/SecretsManagerRDSMySQLRotationSingleUser/lambda_function.py
    # Secrets must have following JSON structure
    # {
    #   "username":"user",
    #   "password":"password12",
    #   "engine":"mysql",
    #   "host":"mycluster.asdfasdf.us-east-1.rds.amazonaws.com",
    #   "port":3306,
    #   "dbClusterIdentifier":"mycluster"
    # }
    function_name = "SecretsManager-rotation"
    runtime       = "python3.12"

    # Access to secretsmanager and RDS is required
    subnet_ids         = ["subnet-06fab1b614360aac4", "subnet-0c1c2c8b22c72a201"]
    security_group_ids = ["sg-085666c194cecea0a"]
  }
}
