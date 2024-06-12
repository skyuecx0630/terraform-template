output "docdb" {
  value = { for k, v in var.docdb : k => {
    endpoint = aws_docdb_cluster.docdb[k].endpoint
  } }
}
