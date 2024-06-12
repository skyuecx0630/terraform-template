output "cache" {
  value = { for k, v in var.cache : k => {
    endpoint = v.cluster_enabled ? aws_elasticache_replication_group.cache[k].configuration_endpoint_address : aws_elasticache_replication_group.cache[k].primary_endpoint_address
  } }
}
