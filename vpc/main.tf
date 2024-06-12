data "aws_region" "current" {}

locals {
  is_logs = { for k, v in var.vpc : k => v.flow_log_destination_type == "cloud-watch-logs" }
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.8"

  for_each = var.vpc

  name = each.value.name
  cidr = each.value.cidr

  enable_dns_support   = true
  enable_dns_hostnames = true

  create_igw                          = each.value.enable_internet_gateway
  create_multiple_public_route_tables = false

  enable_nat_gateway     = each.value.enable_nat_gateway
  one_nat_gateway_per_az = true

  create_database_subnet_route_table = true
  create_database_nat_gateway_route  = false

  azs                   = each.value.azs
  public_subnets        = try(each.value.public_subnets, null)
  public_subnet_names   = try(each.value.public_subnet_names, null)
  private_subnets       = try(each.value.private_subnets, null)
  private_subnet_names  = try(each.value.private_subnet_names, null)
  database_subnets      = try(each.value.data_subnets, null)
  database_subnet_names = try(each.value.data_subnet_names, null)

  default_security_group_ingress = each.value.empty_default_security_group ? [] : null
  default_security_group_egress  = each.value.empty_default_security_group ? [] : null

  enable_flow_log                   = each.value.enable_flow_log
  flow_log_traffic_type             = "ALL"
  flow_log_max_aggregation_interval = each.value.flow_log_max_aggregation_interval

  flow_log_destination_type = each.value.flow_log_destination_type
  flow_log_destination_arn  = local.is_logs[each.key] ? null : "arn:aws:s3:::${each.value.flow_log_s3_bucket}"

  create_flow_log_cloudwatch_iam_role             = local.is_logs[each.key]
  create_flow_log_cloudwatch_log_group            = local.is_logs[each.key]
  flow_log_cloudwatch_log_group_retention_in_days = 90
}

resource "aws_vpc_endpoint" "endpoint" {
  for_each = { for k, v in var.vpc : k => v if v.enable_s3_gateway_endpoint }

  vpc_id            = module.vpc[each.key].vpc_id
  service_name      = "com.amazonaws.${data.aws_region.current.name}.s3"
  vpc_endpoint_type = "Gateway"

  route_table_ids = concat(
    module.vpc[each.key].public_route_table_ids,
    module.vpc[each.key].private_route_table_ids,
    module.vpc[each.key].database_route_table_ids,
  )
}
