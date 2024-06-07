module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.13"

  for_each = var.cluster

  cluster_name = each.value.cluster_name

  vpc_id                   = each.value.vpc_id
  subnet_ids               = each.value.subnet_ids
  control_plane_subnet_ids = each.value.control_plane_subnet_ids

  enable_cluster_creator_admin_permissions = true
  cluster_endpoint_public_access           = each.value.cluster_endpoint_public_access
  cluster_endpoint_public_access_cidrs     = each.value.cluster_endpoint_public_access_cidrs

  create_cluster_security_group = !each.value.use_fargate
  create_node_security_group    = !each.value.use_fargate

  fargate_profiles = each.value.use_fargate ? {
    fargate = {
      name      = "fargate"
      selectors = [{ namespace = "*" }]
    }
  } : {}

  eks_managed_node_groups = each.value.use_fargate ? {} : {
    node_group = {
      name            = each.value.node_group.name
      use_name_prefix = each.value.node_group.use_name_prefix

      min_size     = each.value.node_group.min_size
      max_size     = each.value.node_group.max_size
      desired_size = each.value.node_group.desired_size

      labels = each.value.node_group.labels
      taints = each.value.node_group.taints

      block_device_mappings = {
        xvda = {
          device_name = "/dev/xvda"
          ebs = {
            volume_size           = 30
            volume_type           = "gp3"
            iops                  = 3000
            throughput            = 150
            encrypted             = true
            delete_on_termination = true
          }
        }
      }
      subnet_ids        = each.value.subnet_ids
      enable_monitoring = true
      metadata_options = {
        http_endpoint               = "enabled"
        http_tokens                 = "required"
        http_put_response_hop_limit = 2
        instance_metadata_tags      = "disabled"
      }

      launch_template_tags = {
        # enable discovery of autoscaling groups by cluster-autoscaler
        "k8s.io/cluster-autoscaler/enabled" : true,
        "k8s.io/cluster-autoscaler/${each.value.cluster_name}" : "owned",
      }
    }
  }

  cluster_addons = {
    coredns = {
      most_recent = true
      configuration_values = each.value.use_fargate ? jsonencode({
        computeType = "fargate"
      }) : null
    }
    kube-proxy = {
      most_recent = true
    }
    vpc-cni = {
      most_recent = true
    }
  }

  cluster_enabled_log_types = ["audit", "api", "authenticator", "scheduler", "controllerManager"]
}
