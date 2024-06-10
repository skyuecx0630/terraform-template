resource "aws_docdb_cluster" "docdb" {
  for_each = var.docdb

  cluster_identifier = each.value.name
  engine             = "docdb"
  engine_version     = each.value.engine_version

  db_cluster_parameter_group_name = aws_docdb_cluster_parameter_group.cluster_parameter_group[each.key].id
  db_subnet_group_name            = aws_docdb_subnet_group.subnet_group[each.key].id

  port                   = each.value.port
  vpc_security_group_ids = each.value.security_group_ids

  storage_encrypted = true
  kms_key_id        = module.kms_key[each.key].key_arn

  master_username = each.value.master_username
  master_password = each.value.master_password

  skip_final_snapshot = true

  backup_retention_period         = 7
  enabled_cloudwatch_logs_exports = ["audit", "profiler"]
}

resource "aws_docdb_cluster_instance" "instance1" {
  for_each = var.docdb

  identifier     = "${each.value.name}-instance-1"
  instance_class = each.value.instance_type

  cluster_identifier = aws_docdb_cluster.docdb[each.key].id
  engine             = "docdb"

  enable_performance_insights     = true
  performance_insights_kms_key_id = module.kms_key[each.key].key_id
}

resource "aws_docdb_cluster_instance" "instance2" {
  for_each = var.docdb

  identifier     = "${each.value.name}-instance-2"
  instance_class = each.value.instance_type

  cluster_identifier = aws_docdb_cluster.docdb[each.key].id
  engine             = "docdb"

  enable_performance_insights     = true
  performance_insights_kms_key_id = module.kms_key[each.key].key_id
}

resource "aws_docdb_subnet_group" "subnet_group" {
  for_each = var.docdb

  name        = "${each.value.name}-subnet-group"
  description = "${each.value.name} subnet group"
  subnet_ids  = each.value.subnet_ids
}

resource "aws_docdb_cluster_parameter_group" "cluster_parameter_group" {
  for_each = var.docdb

  name        = "${each.value.name}-cluster-parameter-group"
  description = "${each.value.name} cluster parameter group"
  family      = each.value.parameter_group_family
}

module "kms_key" {
  source  = "terraform-aws-modules/kms/aws"
  version = "~> 3.0"

  for_each = var.docdb

  description             = "KMS key for encrypting DocumentDB ${each.value.name}"
  deletion_window_in_days = 7
  enable_key_rotation     = true
  key_usage               = "ENCRYPT_DECRYPT"

  aliases = ["docdb/${each.value.name}"]
}
