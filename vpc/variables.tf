variable "resource_name_tag_perfix" {
  type        = string
  description = "Prefix for resource name tag"
  default     = "skills"
}

variable "vpc_cidr" {
  type        = string
  description = "CIDR for VPC"
  default     = "10.0.0.0/16"
}

variable "create_vpc_flow_log_cloudwatch_logs" {
  type        = number
  description = "Enable VPC flow log and publish to CloudWatch Logs"
  default     = 1
}
