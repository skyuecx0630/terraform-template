variable "vpc" {
  type        = map(any)
  description = "Map for VPC"

  default = {
    vpc = {
      name = "skills-vpc"
      cidr = "10.0.0.0/16"

      enable_internet_gateway = true
      enable_nat_gateway      = true

      enable_s3_gateway_endpoint   = true
      empty_default_security_group = true

      azs                  = ["us-east-1a", "us-east-1b"]
      public_subnet_names  = ["skills-public-subnet-a", "skills-public-subnet-b"]
      private_subnet_names = ["skills-private-subnet-a", "skills-private-subnet-b"]
      data_subnet_names    = ["skills-data-subnet-a", "skills-data-subnet-b"]
      public_subnets       = ["10.0.0.0/24", "10.0.1.0/24"]
      private_subnets      = ["10.0.10.0/24", "10.0.11.0/24"]
      data_subnets         = ["10.0.20.0/24", "10.0.21.0/24"]

      enable_flow_log                           = true
      flow_log_max_aggregation_interval         = 60                 # 60 or 600 (10 minutes)
      flow_log_destination_type                 = "cloud-watch-logs" # cloud-watch-logs | s3 | kinesis-data-firehose
      flow_log_cloudwatch_log_group_name_prefix = "/aws/vpc/flow-log"
      flow_log_s3_bucket                        = ""
    }
  }
}
