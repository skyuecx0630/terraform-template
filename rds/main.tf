resource "aws_rds_cluster" "rds_cluster" {
  for_each = var.rds

  cluster_identifier = each.value.cluster_name

  engine_mode    = "provisioned"
  engine         = each.value.engine
  engine_version = each.value.engine_version

  db_subnet_group_name   = aws_db_subnet_group.subnet_group[each.key].id
  vpc_security_group_ids = each.value.security_group_ids

  port          = each.value.port
  database_name = try(each.value.initial_database_name, "") != "" ? each.value.initial_database_name : null

  db_cluster_parameter_group_name  = aws_rds_cluster_parameter_group.rds_cluster_parameter_group[each.key].name
  db_instance_parameter_group_name = aws_db_parameter_group.rds_parameter_group[each.key].name

  master_username                     = each.value.master_username
  manage_master_user_password         = true
  master_user_secret_kms_key_id       = module.kms_key[each.key].key_id
  iam_database_authentication_enabled = true

  storage_encrypted       = true
  kms_key_id              = module.kms_key[each.key].key_arn
  backup_retention_period = 7
  skip_final_snapshot     = true
  copy_tags_to_snapshot   = true

  backtrack_window = each.value.engine == "aurora-mysql" ? 60 * 60 * 24 : null # 1 day

  enabled_cloudwatch_logs_exports = each.value.engine == "aurora-mysql" ? [
    "error", "general", "slowquery", "audit"
  ] : ["postgresql"]

}

resource "aws_rds_cluster_instance" "instance1" {
  for_each = var.rds

  identifier         = "${each.value.cluster_name}-instance-1"
  cluster_identifier = aws_rds_cluster.rds_cluster[each.key].id

  instance_class = each.value.instance_type
  engine         = each.value.engine
  engine_version = each.value.engine_version

  db_parameter_group_name = aws_db_parameter_group.rds_parameter_group[each.key].name

  monitoring_interval          = 60
  monitoring_role_arn          = aws_iam_role.monitoring_role[each.key].arn
  performance_insights_enabled = !startswith(each.value.instance_type, "db.t")
}

resource "aws_rds_cluster_instance" "instance2" {
  for_each = var.rds

  identifier         = "${each.value.cluster_name}-instance-2"
  cluster_identifier = aws_rds_cluster.rds_cluster[each.key].id

  instance_class = each.value.instance_type
  engine         = each.value.engine
  engine_version = each.value.engine_version

  db_parameter_group_name = aws_db_parameter_group.rds_parameter_group[each.key].name

  monitoring_interval          = 60
  monitoring_role_arn          = aws_iam_role.monitoring_role[each.key].arn
  performance_insights_enabled = !startswith(each.value.instance_type, "db.t")
}

resource "aws_rds_cluster_parameter_group" "rds_cluster_parameter_group" {
  for_each = var.rds

  name        = "${each.value.cluster_name}-cluster-parameter-group"
  description = "cluster parameter group"
  family      = each.value.parameter_group_family

  dynamic "parameter" {
    for_each = each.value.engine == "aurora-mysql" ? [1] : []

    content {
      name         = "performance_schema"
      value        = "1"
      apply_method = "pending-reboot"
    }
  }
}

resource "aws_db_parameter_group" "rds_parameter_group" {
  for_each = var.rds

  name        = "${each.value.cluster_name}-parameter-group"
  description = "parameter group"
  family      = each.value.parameter_group_family

  dynamic "parameter" {
    for_each = each.value.engine == "aurora-mysql" ? [1] : []

    content {
      name         = "performance_schema"
      value        = "1"
      apply_method = "pending-reboot"
    }
  }
}

resource "aws_db_subnet_group" "subnet_group" {
  for_each = var.rds

  name        = "${each.value.cluster_name}-subnet-group"
  description = "subnet group"
  subnet_ids  = each.value.subnet_ids
}

module "kms_key" {
  source  = "terraform-aws-modules/kms/aws"
  version = "~> 3.0"

  for_each = var.rds

  description             = "KMS key for encrypting RDS cluster ${each.value.cluster_name}"
  deletion_window_in_days = 7
  enable_key_rotation     = true
  key_usage               = "ENCRYPT_DECRYPT"

  aliases = ["rds/${each.value.cluster_name}"]
}

data "aws_iam_policy_document" "monitoring_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["monitoring.rds.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "monitoring_role" {
  for_each = var.rds

  name = "${each.value.cluster_name}-monitoring-role"

  assume_role_policy = data.aws_iam_policy_document.monitoring_assume_role_policy.json
  managed_policy_arns = [
    "arn:aws:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"
  ]
}
