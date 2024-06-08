variable "rds" {
  type        = map(any)
  description = "Map for RDS"

  default = {
    aurora = {
      cluster_name = "skills-aurora-cluster"

      engine                 = "aurora-mysql"
      engine_version         = "8.0"
      parameter_group_family = "aurora-mysql8.0"

      instance_type = "db.t3.medium"

      master_username = "admin"

      port = 3306

      subnet_ids         = ["subnet-02db9e8b8d788f7d6", "subnet-0a69a201606ca801b"]
      security_group_ids = ["sg-09d6e0ebb9d6573c9"]

      initial_database_name = "test"
    }
    # postgres = {
    #   cluster_name = "skills-postgres-cluster"

    #   engine                 = "aurora-postgresql"
    #   engine_version         = "15"
    #   parameter_group_family = "aurora-postgresql15"

    #   instance_type = "db.t3.medium"

    #   master_username = "postgres"

    #   port               = 5432
    #   subnet_ids         = ["subnet-02db9e8b8d788f7d6", "subnet-0a69a201606ca801b"]
    #   security_group_ids = ["sg-09d6e0ebb9d6573c9"]

    #   initial_database_name = "test"
    # }
  }
}
