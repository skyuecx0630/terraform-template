variable "cache" {
  type        = map(any)
  description = "Map for Elasticache clusters"

  default = {
    cache = {
      name                   = "skills-cache"
      engine                 = "redis"
      engine_version         = "7.0"
      parameter_group_family = "redis7"

      cluster_enabled            = false
      transit_encryption_enabled = false

      node_type          = "cache.t2.micro"
      shard_count        = 2 # ignored if cluster is disabled
      replicas_per_shard = 2 # primary + replicas = 3 nodes

      port               = 6379
      subnet_ids         = ["subnet-02db9e8b8d788f7d6", "subnet-0a69a201606ca801b"]
      security_group_ids = ["sg-03da76d0b78d6fba2"]
    }
    # cache_cluster = {
    #   name                   = "skills-cache-cluster"
    #   engine                 = "redis"
    #   engine_version         = "7.0"
    #   parameter_group_family = "redis7"

    #   cluster_enabled            = true
    #   transit_encryption_enabled = false

    #   node_type          = "cache.t2.micro"
    #   shard_count        = 2 # ignored if cluster is disabled
    #   replicas_per_shard = 2 # primary + replicas = 3 nodes per shard

    #   port               = 6379
    #   subnet_ids         = ["subnet-02db9e8b8d788f7d6", "subnet-0a69a201606ca801b"]
    #   security_group_ids = ["sg-03da76d0b78d6fba2"]
    # }
  }
}
