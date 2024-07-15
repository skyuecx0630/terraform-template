variable "ecs_optimized_ami" {
  type        = string
  description = "SSM parameter ecs_optimized_ami"
  default     = "/aws/service/ecs/optimized-ami/amazon-linux-2023/recommended"
  # default     = "/aws/service/ecs/optimized-ami/amazon-linux-2/recommended"
}

variable "cluster" {
  type        = any
  description = "Map for ECS Cluster"
  default = {
    cluster = {
      name = "skills-cluster"

      enable_fargate = true
      enable_asg     = false

      asg_name          = "skills-cluster-worker"
      asg_instance_name = "skills-cluster-worker"
      asg_instance_type = "t3.small"

      asg_security_group_ids = ["sg-02c94423f99b300c9"]
      asg_subnet_ids         = ["subnet-0da434b7a5ba13737", "subnet-0f44a995e7e181d92"]
    }
  }
}
