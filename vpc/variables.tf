variable "vpc" {
  type        = any
  description = "Map for VPC"

  default = {
    name = "skills-vpc"
    cidr = "10.0.0.0/16"

    enable_internet_gateway = true
    enable_nat_gateway      = true

    empty_default_security_group = true

    azs                  = ["us-east-1a", "us-east-1b"]
    public_subnet_names  = ["skills-public-subnet-a", "skills-public-subnet-b"]
    private_subnet_names = ["skills-private-subnet-a", "skills-private-subnet-b"]
    intra_subnet_names   = ["skills-data-subnet-a", "skills-data-subnet-b"]
    public_subnets       = ["10.0.0.0/24", "10.0.1.0/24"]
    private_subnets      = ["10.0.10.0/24", "10.0.11.0/24"]
    intra_subnets        = ["10.0.20.0/24", "10.0.21.0/24"]

    vpc_endpoint_security_group_name = "skills-endpoint-sg"
    vpc_endpoints = [
      "com.amazonaws.us-east-1.s3",
      "com.amazonaws.us-east-1.dynamodb",
      "com.amazonaws.us-east-1.sts",

      # "com.amazonaws.us-east-1.ecr.api",
      # "com.amazonaws.us-east-1.ecr.dkr",
      # "com.amazonaws.us-east-1.secretsmanager",
      # "com.amazonaws.us-east-1.kms",

      # "com.amazonaws.us-east-1.eks",
      # "com.amazonaws.us-east-1.autoscaling",
      # "com.amazonaws.us-east-1.elasticloadbalancing",

      # "com.amazonaws.us-east-1.ssm",
      # "com.amazonaws.us-east-1.ssmmessages",
      # "com.amazonaws.us-east-1.ec2messages",
    ]

    enable_flow_log                           = true
    flow_log_max_aggregation_interval         = 60                 # 60 or 600 (10 minutes)
    flow_log_destination_type                 = "cloud-watch-logs" # cloud-watch-logs | s3 | kinesis-data-firehose
    flow_log_cloudwatch_log_group_name_prefix = "/aws/vpc/flow-log"
    flow_log_s3_bucket                        = ""
  }
}
