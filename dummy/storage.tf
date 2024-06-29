# ==================================================
# RDS
# ==================================================

resource "aws_rds_cluster" "rds_cluster" {
  count = var.dummy.rds ? 1 : 0

  cluster_identifier = "dummy-aurora-cluster"

  engine_mode    = "provisioned"
  engine         = "aurora-mysql"
  engine_version = "8.0"

  db_subnet_group_name   = aws_db_subnet_group.subnet_group[0].id
  vpc_security_group_ids = [module.vpc[0].default_security_group_id]

  port          = 3306
  database_name = "test"

  db_cluster_parameter_group_name  = aws_rds_cluster_parameter_group.rds_cluster_parameter_group[0].name
  db_instance_parameter_group_name = aws_db_parameter_group.rds_parameter_group[0].name

  master_username                     = "admin"
  manage_master_user_password         = true
  master_user_secret_kms_key_id       = module.kms_key[0].key_id
  iam_database_authentication_enabled = true

  storage_encrypted       = true
  kms_key_id              = module.kms_key[0].key_arn
  backup_retention_period = 7
  skip_final_snapshot     = true
  copy_tags_to_snapshot   = true

  backtrack_window = 60 * 60 * 24

  enabled_cloudwatch_logs_exports = ["error", "general", "slowquery", "audit"]
}

resource "aws_rds_cluster_instance" "instance1" {
  count = var.dummy.rds ? 1 : 0

  identifier         = "dummy-aurora-instance-1"
  cluster_identifier = aws_rds_cluster.rds_cluster[0].id

  instance_class = "db.t3.medium"
  engine         = "aurora-mysql"
  engine_version = "8.0"

  db_parameter_group_name = aws_db_parameter_group.rds_parameter_group[0].name

  monitoring_interval = 60
  monitoring_role_arn = aws_iam_role.monitoring_role[0].arn
}

resource "aws_rds_cluster_parameter_group" "rds_cluster_parameter_group" {
  count = var.dummy.rds ? 1 : 0

  name        = "dummy-aurora-cluster-parameter-group"
  description = "cluster parameter group"
  family      = "aurora-mysql8.0"

  parameter {
    name         = "performance_schema"
    value        = "1"
    apply_method = "pending-reboot"
  }
}

resource "aws_db_parameter_group" "rds_parameter_group" {
  count = var.dummy.rds ? 1 : 0

  name        = "dummy-aurora-parameter-group"
  description = "parameter group"
  family      = "aurora-mysql8.0"

  parameter {
    name         = "performance_schema"
    value        = "1"
    apply_method = "pending-reboot"
  }
}

resource "aws_db_subnet_group" "subnet_group" {
  count = var.dummy.rds ? 1 : 0

  name        = "dummy-aurora-cluster-subnet-group"
  description = "subnet group"
  subnet_ids  = module.vpc[0].intra_subnets
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
  count = var.dummy.rds ? 1 : 0

  name = "dummy-aurora-cluster-monitoring-role"

  assume_role_policy = data.aws_iam_policy_document.monitoring_assume_role_policy.json
  managed_policy_arns = [
    "arn:aws:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"
  ]
}

# ==================================================
# ElastiCache
# ==================================================

resource "aws_elasticache_replication_group" "cache" {
  count = var.dummy.cache ? 1 : 0

  replication_group_id = "dummy-cache"
  description          = "Redis cache"
  engine               = "redis"
  engine_version       = "7.0"

  node_type               = "cache.t2.micro"
  num_node_groups         = 1
  replicas_per_node_group = 1

  port = 6379

  security_group_ids   = [module.vpc[0].default_security_group_id]
  subnet_group_name    = aws_elasticache_subnet_group.cache_subnet_group[0].name
  parameter_group_name = aws_elasticache_parameter_group.cache_parameter_group[0].name

  multi_az_enabled           = true
  automatic_failover_enabled = true

  at_rest_encryption_enabled = true
  transit_encryption_enabled = false

  snapshot_retention_limit = 1

  log_delivery_configuration {
    log_type         = "slow-log"
    log_format       = "json"
    destination_type = "cloudwatch-logs"
    destination      = aws_cloudwatch_log_group.cache_log_group[0].name
  }

  log_delivery_configuration {
    log_type         = "engine-log"
    log_format       = "json"
    destination_type = "cloudwatch-logs"
    destination      = aws_cloudwatch_log_group.cache_log_group[0].name
  }
}

resource "aws_elasticache_parameter_group" "cache_parameter_group" {
  count = var.dummy.cache ? 1 : 0

  name        = "dummy-cache-parameter-group"
  description = "Parameter group for dummy-cache ElastiCache"
  family      = "redis7"
  parameter {
    name  = "cluster-enabled"
    value = "no"
  }
}

resource "aws_elasticache_subnet_group" "cache_subnet_group" {
  count = var.dummy.cache ? 1 : 0

  name        = "dummy-cache-subnet-group"
  description = "Subnet group for dummy-cache ElastiCache"
  subnet_ids  = module.vpc[0].intra_subnets
}

resource "aws_cloudwatch_log_group" "cache_log_group" {
  count = var.dummy.cache ? 1 : 0

  name              = "/elasticache/dummy-cache"
  retention_in_days = 7
}

# ==================================================
# DocDB
# ==================================================

resource "aws_docdb_cluster" "docdb" {
  count = var.dummy.docdb ? 1 : 0

  cluster_identifier = "dummy-docdb"
  engine             = "docdb"
  engine_version     = "5.0.0"

  db_cluster_parameter_group_name = aws_docdb_cluster_parameter_group.cluster_parameter_group[0].id
  db_subnet_group_name            = aws_docdb_subnet_group.subnet_group[0].id

  port                   = 27017
  vpc_security_group_ids = [module.vpc[0].default_security_group_id]

  storage_encrypted = true
  kms_key_id        = module.kms_key[0].key_arn

  master_username = "skills"
  master_password = "asdf1234"

  skip_final_snapshot = true

  backup_retention_period         = 7
  enabled_cloudwatch_logs_exports = ["audit", "profiler"]
}

resource "aws_docdb_cluster_instance" "instance1" {
  count = var.dummy.docdb ? 1 : 0

  identifier     = "dummy-docdb-instance-1"
  instance_class = "db.t4g.medium"

  cluster_identifier = aws_docdb_cluster.docdb[0].id
  engine             = "docdb"

  enable_performance_insights     = true
  performance_insights_kms_key_id = module.kms_key[0].key_id
}

resource "aws_docdb_subnet_group" "subnet_group" {
  count = var.dummy.docdb ? 1 : 0

  name        = "dummy-docdb-subnet-group"
  description = "dummy-docdb subnet group"
  subnet_ids  = module.vpc[0].intra_subnets
}

resource "aws_docdb_cluster_parameter_group" "cluster_parameter_group" {
  count = var.dummy.docdb ? 1 : 0

  name        = "dummy-docdb-cluster-parameter-group"
  description = "dummy-docdb cluster parameter group"
  family      = "docdb5.0"
}

# ==================================================
# EFS
# ==================================================

resource "aws_efs_file_system" "efs" {
  count = var.dummy.efs ? 1 : 0

  encrypted       = true
  throughput_mode = "elastic"

  lifecycle_policy {
    transition_to_ia = "AFTER_30_DAYS"
  }

  lifecycle_policy {
    transition_to_archive = "AFTER_60_DAYS"
  }

  tags = {
    "Name" = "dummy-efs"
  }
}


resource "aws_efs_file_system_policy" "efs_policy" {
  count = var.dummy.efs ? 1 : 0

  file_system_id = aws_efs_file_system.efs[0].id
  policy         = <<EOT
  {
    "Version" : "2012-10-17",
    "Id" : "efs-policy",
    "Statement" : [
      {
        "Sid" : "mount-target-only",
        "Effect" : "Allow",
        "Principal" : {
          "AWS" : "*"
        },
        "Action" : [
          "elasticfilesystem:ClientRootAccess",
          "elasticfilesystem:ClientWrite",
          "elasticfilesystem:ClientMount"
        ],
        "Resource" : "${aws_efs_file_system.efs[0].arn}",
        "Condition" : {
          "Bool" : {
            "elasticfilesystem:AccessedViaMountTarget" : "true"
          }
        }
      },
      {
        "Sid" : "deny-non-tls",
        "Effect" : "Deny",
        "Principal" : {
          "AWS" : "*"
        },
        "Action" : "*",
        "Resource" : "${aws_efs_file_system.efs[0].arn}",
        "Condition" : {
          "Bool" : {
            "aws:SecureTransport" : "false"
          }
        }
      }
    ]
  }
  EOT
}

resource "aws_efs_access_point" "efs_access_point" {
  count = var.dummy.efs ? 1 : 0

  file_system_id = aws_efs_file_system.efs[0].id
  posix_user {
    uid = 10001
    gid = 10001
  }

  root_directory {
    path = "/dummy"
    creation_info {
      owner_uid   = 10001
      owner_gid   = 10001
      permissions = "0755"
    }
  }

  tags = {
    "Name" = "dummy-efs-access-point"
  }
}

resource "aws_efs_mount_target" "efs_mount_target_1" {
  count = var.dummy.efs ? 1 : 0

  file_system_id = aws_efs_file_system.efs[0].id

  subnet_id       = module.vpc[0].intra_subnets[0]
  security_groups = [module.vpc[0].default_security_group_id]
}

resource "aws_efs_mount_target" "efs_mount_target_2" {
  count = var.dummy.efs ? 1 : 0

  file_system_id = aws_efs_file_system.efs[0].id

  subnet_id       = module.vpc[0].intra_subnets[1]
  security_groups = [module.vpc[0].default_security_group_id]
}

resource "aws_efs_backup_policy" "efs_backup_policy" {
  count = var.dummy.efs ? 1 : 0

  file_system_id = aws_efs_file_system.efs[0].id

  backup_policy {
    status = "ENABLED"
  }
}

# ==================================================
# DynamoDB
# ==================================================


resource "aws_dynamodb_table" "table" {
  count = var.dummy.ddb ? 1 : 0

  name         = "dummy"
  billing_mode = "PAY_PER_REQUEST"

  hash_key = "id"

  attribute {
    name = "id"
    type = "S"
  }

  point_in_time_recovery {
    enabled = true
  }

  server_side_encryption {
    enabled     = true
    kms_key_arn = module.kms_key[0].key_arn
  }

  tags = {
    "Name" = "dummy"
  }
}
