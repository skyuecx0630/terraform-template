output "preset" {
  value = {
    for k, v in var.preset :
    aws_security_group.preset_security_group[k].name =>
    aws_security_group.preset_security_group[k].id
  }
}
output "security_group" {
  value = { for k, v in var.security_group : k => aws_security_group.security_group[k].id }
}
