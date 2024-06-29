data "aws_default_tags" "default" {}
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}
data "aws_availability_zones" "available" {
  state = "available"
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.8"

  count = var.dummy.vpc ? 1 : 0

  name = "dummy-vpc"
  cidr = "10.123.0.0/16"

  enable_dns_support   = true
  enable_dns_hostnames = true

  create_igw                          = true
  create_multiple_public_route_tables = false

  enable_nat_gateway = true
  single_nat_gateway = true

  azs                  = slice(data.aws_availability_zones.available.names, 0, 2)
  public_subnets       = ["10.123.0.0/24", "10.123.1.0/24"]
  public_subnet_names  = ["dummy-public-subnet-a", "dummy-public-subnet-b"]
  private_subnets      = ["10.123.10.0/24", "10.123.11.0/24"]
  private_subnet_names = ["dummy-private-subnet-a", "dummy-private-subnet-b"]
  intra_subnets        = ["10.123.20.0/24", "10.123.21.0/24"]
  intra_subnet_names   = ["dummy-data-subnet-a", "dummy-data-subnet-b"]

  default_security_group_ingress = []
  default_security_group_egress  = []

  enable_flow_log                   = true
  flow_log_traffic_type             = "ALL"
  flow_log_max_aggregation_interval = 60

  flow_log_destination_type = "cloud-watch-logs"

  create_flow_log_cloudwatch_iam_role             = true
  create_flow_log_cloudwatch_log_group            = true
  flow_log_cloudwatch_log_group_retention_in_days = 90
}

module "s3_bucket" {
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "~> 4.1"

  count = var.dummy.s3 ? 1 : 0

  bucket        = "dummy-${data.aws_caller_identity.current.account_id}-logs"
  force_destroy = true

  attach_deny_insecure_transport_policy = true
  attach_elb_log_delivery_policy        = true

  server_side_encryption_configuration = {
    rule = {
      apply_server_side_encryption_by_default = {
        sse_algorithm = "AES256"
      }
      bucket_key_enabled = true
    }
  }

  versioning = {
    enabled = true
  }

  lifecycle_rule = [
    {
      id      = "log"
      enabled = true

      transition = [
        {
          days          = 30
          storage_class = "STANDARD_IA"
        },
        {
          days          = 60
          storage_class = "ONEZONE_IA"
        }
      ]
    }
  ]

  intelligent_tiering = {
    general = {
      status = "Enabled"
      tiering = {
        ARCHIVE_ACCESS = {
          days = 90
        }
        DEEP_ARCHIVE_ACCESS = {
          days = 180
        }
      }
    }
  }
}

module "kms_key" {
  source  = "terraform-aws-modules/kms/aws"
  version = "~> 3.0"

  count = 1

  description             = "KMS key for dummy resources"
  deletion_window_in_days = 7
  enable_key_rotation     = true
  key_usage               = "ENCRYPT_DECRYPT"

  aliases = ["dummy/key"]
}

