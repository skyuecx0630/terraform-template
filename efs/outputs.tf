output "efs" {
  value = {
    for k, v in var.efs : k => {
      fs-id   = aws_efs_file_system.efs[k].id
      fsap-id = aws_efs_access_point.efs_access_point[k].id
    }
  }
}
