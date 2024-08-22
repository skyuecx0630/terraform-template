module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.13"

  for_each = var.cluster

  cluster_name    = each.value.cluster_name
  cluster_version = each.value.cluster_version

  vpc_id                   = each.value.vpc_id
  subnet_ids               = each.value.subnet_ids
  control_plane_subnet_ids = try(each.value.control_plane_subnet_ids, null)

  enable_cluster_creator_admin_permissions = true
  cluster_endpoint_public_access           = each.value.cluster_endpoint_public_access
  cluster_endpoint_public_access_cidrs     = each.value.cluster_endpoint_public_access_cidrs

  create_cluster_security_group = length(each.value.node_group) > 0
  create_node_security_group    = length(each.value.node_group) > 0

  fargate_profiles = try(each.value.fargate, {})

  eks_managed_node_groups = {
    for k, v in each.value.node_group : k => {
      name            = v.name
      use_name_prefix = false

      create_iam_role          = v.iam_role_arn != null ? false : true
      iam_role_name            = v.iam_role_arn != null ? null : "${v.name}-role"
      iam_role_use_name_prefix = false
      iam_role_arn             = v.iam_role_arn

      iam_role_additional_policies = {
        ssm = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
      }

      min_size     = v.min_size
      max_size     = v.max_size
      desired_size = v.desired_size

      ami_type       = v.ami_type
      instance_types = v.instance_types

      labels = v.labels
      taints = v.taints

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
        http_put_response_hop_limit = v.metadata_hop_limit
        instance_metadata_tags      = "disabled"
      }

      launch_template_tags = {
        Name = v.worker_name
        # enable discovery of autoscaling groups by cluster-autoscaler
        "k8s.io/cluster-autoscaler/enabled" : true,
        "k8s.io/cluster-autoscaler/${each.value.cluster_name}" : "owned",
      }
    }
  }

  cluster_addons = {
    coredns = {
      most_recent = true
      configuration_values = each.value.coredns_on_fargate ? jsonencode({
        computeType = "fargate"
        affinity    = null
      }) : null
    }
    kube-proxy = {
      most_recent = true
    }
    vpc-cni = {
      most_recent = true
    }

    # eks-pod-identity-agent = {
    #   most_recent = true
    # }
    # aws-efs-csi-driver = {
    #   most_recent = true
    # }
    amazon-cloudwatch-observability = {
      most_recent = true
      configuration_values = jsonencode({
        containerLogs = {
          fluentBit = {
            config = {
              service       = file("fluentbit/fluent-bit.conf")
              customParsers = file("fluentbit/parsers.conf")
              extraFiles = {
                "application-log.conf" = file("fluentbit/application-log.conf")
                "dataplane-log.conf"   = file("fluentbit/dataplane-log.conf")
                "host-log.conf"        = file("fluentbit/host-log.conf")
              }
            }
          }
        }
      })
    }

    # # For Configuration Schema
    # export K8S_VERSION="1.29"
    # export ADDON_NAME="eks-pod-identity-agent"
    # export ADDON_VERSION=$(aws eks describe-addon-versions --kubernetes-version $K8S_VERSION --addon-name $ADDON_NAME --query addons[].addonVersions[0].addonVersion --output text)
    # aws eks describe-addon-configuration --addon-name $ADDON_NAME --addon-version $ADDON_VERSION --query configurationSchema --output text | jq 
  }

  cluster_enabled_log_types = ["audit", "api", "authenticator", "scheduler", "controllerManager"]
}
