data "aws_region" "current" {}

locals {
  is_logs = var.vpc.flow_log_destination_type == "cloud-watch-logs"
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.8"

  name = var.vpc.name
  cidr = var.vpc.cidr

  enable_dns_support   = true
  enable_dns_hostnames = true

  create_igw                          = var.vpc.enable_internet_gateway
  create_multiple_public_route_tables = false

  enable_nat_gateway     = var.vpc.enable_nat_gateway
  one_nat_gateway_per_az = true

  azs                  = var.vpc.azs
  public_subnets       = try(var.vpc.public_subnets, null)
  public_subnet_names  = try(var.vpc.public_subnet_names, null)
  private_subnets      = try(var.vpc.private_subnets, null)
  private_subnet_names = try(var.vpc.private_subnet_names, null)
  intra_subnets        = try(var.vpc.intra_subnets, null)
  intra_subnet_names   = try(var.vpc.intra_subnet_names, null)

  default_security_group_ingress = var.vpc.empty_default_security_group ? [] : null
  default_security_group_egress  = var.vpc.empty_default_security_group ? [] : null

  enable_flow_log                   = var.vpc.enable_flow_log
  flow_log_traffic_type             = "ALL"
  flow_log_max_aggregation_interval = var.vpc.flow_log_max_aggregation_interval

  flow_log_destination_type = var.vpc.flow_log_destination_type
  flow_log_destination_arn  = local.is_logs ? null : "arn:aws:s3:::${var.vpc.flow_log_s3_bucket}"

  create_flow_log_cloudwatch_iam_role             = local.is_logs
  create_flow_log_cloudwatch_log_group            = local.is_logs
  flow_log_cloudwatch_log_group_retention_in_days = 90
}

resource "aws_vpc_endpoint" "gateway_endpoint" {
  for_each = toset([
    for service_name in var.vpc.vpc_endpoints :
    service_name if contains([
      "com.amazonaws.${data.aws_region.current.name}.s3",
      "com.amazonaws.${data.aws_region.current.name}.dynamodb",
    ], service_name)
  ])

  vpc_id            = module.vpc.vpc_id
  service_name      = each.key
  vpc_endpoint_type = "Gateway"

  route_table_ids = concat(
    module.vpc.public_route_table_ids,
    module.vpc.private_route_table_ids,
    module.vpc.database_route_table_ids,
  )

  tags = {
    Name = trimprefix(each.key, "com.amazonaws.${data.aws_region.current.name}.")
  }
}

resource "aws_vpc_endpoint" "interface_endpoint" {
  for_each = toset([
    for service_name in var.vpc.vpc_endpoints :
    service_name if !contains([
      "com.amazonaws.${data.aws_region.current.name}.s3",
      "com.amazonaws.${data.aws_region.current.name}.dynamodb",
    ], service_name)
  ])

  vpc_id            = module.vpc.vpc_id
  service_name      = each.key
  vpc_endpoint_type = "Interface"

  private_dns_enabled = true

  subnet_ids         = module.vpc.private_subnets
  security_group_ids = [aws_security_group.endpoint_sg.id]

  tags = {
    Name = trimprefix(each.key, "com.amazonaws.${data.aws_region.current.name}.")
  }
}

resource "aws_security_group" "endpoint_sg" {
  name        = var.vpc.vpc_endpoint_security_group_name
  description = var.vpc.vpc_endpoint_security_group_name
  vpc_id      = module.vpc.vpc_id

  ingress {
    protocol    = "tcp"
    cidr_blocks = [var.vpc.cidr]
    from_port   = 443
    to_port     = 443
    description = "from VPC CIDR"
  }

  tags = {
    Name = var.vpc.vpc_endpoint_security_group_name
  }
}
