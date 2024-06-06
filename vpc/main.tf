provider "aws" {
  default_tags {
    tags = {
      "project" = "skills"
      "owner"   = "hmoon"
    }
  }
}

locals {
  azs = slice(data.aws_availability_zones.available.names, 0, 2)

  vpc_name = "${var.resource_name_tag_perfix}-vpc"
  vpc_cidr = var.vpc_cidr

  public_subnets      = [for k, v in local.azs : cidrsubnet(var.vpc_cidr, 4, k)]
  public_subnet_names = [for k, v in local.azs : "${var.resource_name_tag_perfix}-public-subnet-${v}"]

  private_subnets      = [for k, v in local.azs : cidrsubnet(var.vpc_cidr, 4, k + 2)]
  private_subnet_names = [for k, v in local.azs : "${var.resource_name_tag_perfix}-private-subnet-${v}"]
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.8"

  name = local.vpc_name
  cidr = local.vpc_cidr

  azs                  = local.azs
  public_subnets       = local.public_subnets
  public_subnet_names  = local.public_subnet_names
  private_subnets      = local.private_subnets
  private_subnet_names = local.private_subnet_names


  create_igw           = true
  enable_dns_hostnames = true
}

resource "aws_flow_log" "vpc_flow_log" {
  count = var.create_vpc_flow_log_cloudwatch_logs

  vpc_id                   = module.vpc.vpc_id
  traffic_type             = "ALL"
  max_aggregation_interval = 60

  log_destination_type = "cloud-watch-logs"
  log_destination      = aws_cloudwatch_log_group.vpc_flow_log_log_group.arn
  iam_role_arn         = aws_iam_role.vpc_flow_log_role.arn

  # log_destination_type = "s3"
  # log_destination = aws_s3_bucket.vpc_flow_logs_bucket.arn
}

# resource "aws_s3_bucket" "vpc_flow_logs_bucket" {
#   bucket_prefix = "${var.resource_name_tag_perfix}-vpc-flow-logs-bucket"
# }

resource "aws_cloudwatch_log_group" "vpc_flow_log_log_group" {
  count = var.create_vpc_flow_log_cloudwatch_logs

  name = "/aws/flow-log/${var.resource_name_tag_perfix}"

  retention_in_days = 365
}

resource "aws_iam_role" "vpc_flow_log_role" {
  count = var.create_vpc_flow_log_cloudwatch_logs

  name_prefix = "${var.resource_name_tag_perfix}-vpc-flow-log-role"
  assume_role_policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Action" : [
          "sts:AssumeRole"
        ],
        "Principal" : {
          "Service" : "vpc-flow-logs.amazonaws.com"
        }
      }
    ]
  })

  inline_policy {
    name = "publish-to-cloudwatch-logs"
    policy = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Effect = "Allow"
          Action = [
            "logs:CreateLogGroup",
            "logs:CreateLogStream",
            "logs:PutLogEvents",
            "logs:DescribeLogGroups",
            "logs:DescribeLogStreams"
          ]
          Resource = "*"
        }
      ]
    })
  }
}
