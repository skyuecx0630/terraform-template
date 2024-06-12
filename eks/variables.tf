variable "cluster" {
  type        = any
  description = "Map for EKS cluster"

  default = {
    cluster = {
      cluster_name    = "skills-cluster"
      cluster_version = "1.29"

      vpc_id                   = "vpc-0ece3b0f4e007c367"
      subnet_ids               = ["subnet-0227c0887f7f841f0", "subnet-0f3d271ec01045dd3"]
      control_plane_subnet_ids = ["subnet-0227c0887f7f841f0", "subnet-0f3d271ec01045dd3"]

      cluster_endpoint_public_access       = false
      cluster_endpoint_public_access_cidrs = ["0.0.0.0/0"]

      use_fargate = false

      node_group = {
        ng1 = {
          name            = "skills-worker-ng"
          worker_name     = "skills-worker"
          use_name_prefix = false

          min_size     = 2
          max_size     = 8
          desired_size = 2

          # Available AMIs
          # AL2_x86_64, AL2_ARM_64
          # BOTTLEROCKET_x86_64, BOTTLEROCKET_ARM_64
          # AL2023_x86_64_STANDARD, AL2023_ARM_64_STANDARD
          ami_type       = "AL2_x86_64"
          instance_types = ["t3.medium"]

          labels = {
            # management = "addon"
          }
          taints = [
            # {
            #   effect = "NO_SCHEDULE"
            #   key    = "management"
            #   value  = "addon"
            # }
          ]
        }
      }
    }

    # fargate = {
    #   cluster_name    = "skills-fargate-cluster"
    #   cluster_version = "1.29"

    #   vpc_id                   = "vpc-0ece3b0f4e007c367"
    #   subnet_ids               = ["subnet-0227c0887f7f841f0", "subnet-0f3d271ec01045dd3"]
    #   control_plane_subnet_ids = ["subnet-0227c0887f7f841f0", "subnet-0f3d271ec01045dd3", "subnet-09b43b80cfa72c577", "subnet-00c324cceaff70f59"]

    #   cluster_endpoint_public_access       = false
    #   cluster_endpoint_public_access_cidrs = ["0.0.0.0/0"]

    #   use_fargate = true

    #   node_group = {}
    # }
  }
}
