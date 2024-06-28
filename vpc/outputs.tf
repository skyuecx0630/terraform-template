output "vpc" {
  value = <<EOT
    vpc_id          = ${jsonencode(module.vpc.vpc_id)}
    public_subnets  = ${jsonencode(module.vpc.public_subnets)}
    private_subnets = ${jsonencode(module.vpc.private_subnets)}
    intra_subnets   = ${jsonencode(module.vpc.intra_subnets)}
  EOT
}
