output "vpc" {
  value = { for k, v in module.vpc : k => <<EOT
    vpc_id           = ${jsonencode(v.vpc_id)}
    public_subnets   = ${jsonencode(v.public_subnets)}
    private_subnets  = ${jsonencode(v.private_subnets)}
    database_subnets = ${jsonencode(v.database_subnets)}
    EOT
  }
}
