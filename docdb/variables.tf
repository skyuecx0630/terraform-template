variable "docdb" {
  type        = map(any)
  description = "Map for DocumentDB"

  default = {
    cluster = {
      name                   = "skills-docdb"
      engine_version         = "5.0.0"
      parameter_group_family = "docdb5.0"

      instance_type = "db.t4g.medium" # db.t3.medium
      # instance_count = 2

      master_username = "skills" # "admin" is reserved
      master_password = "asdf1234"

      port               = 27017
      subnet_ids         = ["subnet-02db9e8b8d788f7d6", "subnet-0a69a201606ca801b"]
      security_group_ids = ["sg-0fe515bad1f417497"]
    }
  }
}
