output "rds" {
  value = { for k, v in var.rds : k => {
    endpoint = aws_rds_cluster.aws_rds_cluster.rds_cluster[k].endpoint
  } }
}
