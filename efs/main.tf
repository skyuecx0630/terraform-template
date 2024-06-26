resource "aws_efs_file_system" "efs" {
  for_each = var.efs

  encrypted       = true
  throughput_mode = each.value.throughput_mode

  provisioned_throughput_in_mibps = each.value.throughput_mode == "provisioned" ? each.value.provisioned_throughput_in_mibps : null

  lifecycle_policy {
    transition_to_ia = "AFTER_30_DAYS"
  }

  lifecycle_policy {
    transition_to_archive = "AFTER_60_DAYS"
  }

  tags = {
    "Name" = each.key
  }
}


resource "aws_efs_file_system_policy" "efs_policy" {
  for_each = var.efs

  file_system_id = aws_efs_file_system.efs[each.key].id
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
        "Resource" : "${aws_efs_file_system.efs[each.key].arn}",
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
        "Resource" : "${aws_efs_file_system.efs[each.key].arn}",
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
  for_each = var.efs

  file_system_id = aws_efs_file_system.efs[each.key].id
  posix_user {
    uid = each.value.access_point_uid
    gid = each.value.access_point_gid
  }

  root_directory {
    path = each.value.access_point_path
    creation_info {
      owner_uid   = each.value.access_point_uid
      owner_gid   = each.value.access_point_gid
      permissions = "0755"
    }
  }

  tags = {
    "Name" = "${each.key}-access-point"
  }
}

resource "aws_efs_mount_target" "efs_mount_target_1" {
  for_each = var.efs

  file_system_id = aws_efs_file_system.efs[each.key].id

  subnet_id       = each.value.subnet_ids[0]
  security_groups = each.value.security_group_ids
}

resource "aws_efs_mount_target" "efs_mount_target_2" {
  for_each = var.efs

  file_system_id = aws_efs_file_system.efs[each.key].id

  subnet_id       = each.value.subnet_ids[1]
  security_groups = each.value.security_group_ids
}

resource "aws_efs_backup_policy" "efs_backup_policy" {
  for_each = var.efs

  file_system_id = aws_efs_file_system.efs[each.key].id

  backup_policy {
    status = "ENABLED"
  }
}
