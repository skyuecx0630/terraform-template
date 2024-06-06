variable "resource_name_tag_perfix" {
  type        = string
  description = "Prefix for resource name tag"
  default     = "skills"
}

variable "cluster_name" {
  type        = string
  description = "The name of the cluster"
  default     = "skills-cluster"
}

variable "use_fargate" {
  type        = bool
  description = "Use Fargate or not"
  default     = true
}

###########################################################
# Auto scaling group setups
###########################################################

variable "asg_name" {
  type        = string
  description = "Name of ASG"
  default     = "skills-cluster-worker"
}

variable "instance_name" {
  type        = string
  description = "Name of instance"
  default     = "skills-cluster-worker"
}

variable "instance_type" {
  type        = string
  description = "EC2 instance type"
  default     = "t3.small"
}

variable "security_group_id" {
  type        = string
  description = "Security group id"
  default     = "sg-037845c29b8f81e37"
}

variable "subnet_ids" {
  type        = list(string)
  description = "Subnet ids"
  default     = ["subnet-0227c0887f7f841f0", "subnet-0f3d271ec01045dd3"]
}
