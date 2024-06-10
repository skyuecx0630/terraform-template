resource "aws_elasticache_replication_group" "cache" {
  for_each = var.cache

  replication_group_id = each.value.name
  description          = "Redis ${each.value.name}"
  engine               = each.value.engine
  engine_version       = each.value.engine_version

  node_type               = each.value.node_type
  num_node_groups         = each.value.cluster_enabled ? each.value.shard_count : 1
  replicas_per_node_group = each.value.replicas_per_shard

  port = each.value.port

  security_group_ids   = each.value.security_group_ids
  subnet_group_name    = aws_elasticache_subnet_group.cache_subnet_group[each.key].name
  parameter_group_name = aws_elasticache_parameter_group.cache_parameter_group[each.key].name

  multi_az_enabled           = true
  automatic_failover_enabled = true

  at_rest_encryption_enabled = true
  transit_encryption_enabled = each.value.transit_encryption_enabled

  snapshot_retention_limit = 1

  log_delivery_configuration {
    log_type         = "slow-log"
    log_format       = "json"
    destination_type = "cloudwatch-logs"
    destination      = aws_cloudwatch_log_group.log_group[each.key].name
  }

  log_delivery_configuration {
    log_type         = "engine-log"
    log_format       = "json"
    destination_type = "cloudwatch-logs"
    destination      = aws_cloudwatch_log_group.log_group[each.key].name
  }
}

resource "aws_elasticache_parameter_group" "cache_parameter_group" {
  for_each = var.cache

  name        = "${each.value.name}-parameter-group"
  description = "Parameter group for ${each.value.name} ElastiCache"
  family      = each.value.parameter_group_family
  parameter {
    name  = "cluster-enabled"
    value = each.value.cluster_enabled ? "yes" : "no"
  }
}

resource "aws_elasticache_subnet_group" "cache_subnet_group" {
  for_each = var.cache

  name        = "${each.value.name}-subnet-group"
  description = "Subnet group for ${each.value.name} ElastiCache"
  subnet_ids  = each.value.subnet_ids
}

resource "aws_cloudwatch_log_group" "log_group" {
  for_each = var.cache

  name              = "/elasticache/${each.value.name}"
  retention_in_days = 7
}

module "kms_key" {
  source  = "terraform-aws-modules/kms/aws"
  version = "~> 3.0"

  for_each = var.cache

  description             = "KMS key for encrypting ElastiCache ${each.value.name}"
  deletion_window_in_days = 7
  enable_key_rotation     = true
  key_usage               = "ENCRYPT_DECRYPT"

  aliases = ["elasticache/${each.value.name}"]
}
