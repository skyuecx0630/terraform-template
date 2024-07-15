data "aws_default_tags" "default" {}
data "aws_ssm_parameter" "ecs_optimized_ami" {
  name = var.ecs_optimized_ami
}

module "ecs_cluster" {
  source  = "terraform-aws-modules/ecs/aws"
  version = "~> 5.11"

  for_each = var.cluster

  cluster_name = each.value.name

  default_capacity_provider_use_fargate = each.value.enable_fargate

  fargate_capacity_providers = (each.value.enable_fargate ? {
    FARGATE = {
      default_capacity_provider_strategy = {
        weight = 50
        base   = 20
      }
    }
  } : {})

  autoscaling_capacity_providers = each.value.enable_asg ? {
    asg = {
      auto_scaling_group_arn = module.asg[each.key].autoscaling_group_arn

      managed_scaling = {
        maximum_scaling_step_size = 8
        minimum_scaling_step_size = 1
        status                    = "ENABLED"
        target_capacity           = 100
      }
    }
  } : {}

}

###########################################################
# Auto scaling group
###########################################################

module "asg" {
  source  = "terraform-aws-modules/autoscaling/aws"
  version = "~> 7.6"

  for_each = { for k, v in var.cluster : k => v if v.enable_asg }

  name = each.value.asg_name

  min_size                        = 2
  max_size                        = 8
  ignore_desired_capacity_changes = true

  image_id      = jsondecode(data.aws_ssm_parameter.ecs_optimized_ami.value)["image_id"]
  instance_type = each.value.asg_instance_type

  vpc_zone_identifier = each.value.asg_subnet_ids
  security_groups     = each.value.asg_security_group_ids

  user_data = base64encode(
    <<-EOT
      #!/bin/bash

      cat <<'EOF' >> /etc/ecs/ecs.config
      ECS_CLUSTER=${each.value.name}
      ECS_LOGLEVEL=debug
      EOF
    EOT
  )

  instance_refresh = {
    strategy = "Rolling"
    preferences = {
      # instance_warmup is same with health_check_grace_period
      min_healthy_percentage = 100
      max_healthy_percentage = 200
      skip_matching          = true
    }
    ## A refresh will always be triggered by a change of launch_template
    # triggers = ["launch_template"]
  }

  create_iam_instance_profile = true
  iam_role_name               = "${each.value.asg_name}-role"
  iam_role_policies = {
    AmazonEC2ContainerServiceforEC2Role = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
    AmazonSSMManagedInstanceCore        = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  }

  enable_monitoring = true
  block_device_mappings = [
    {
      # Root volume
      device_name = "/dev/xvda"
      no_device   = 0
      ebs = {
        delete_on_termination = true
        encrypted             = true
        volume_size           = 30
        volume_type           = "gp3"
      }
    }
  ]
  metadata_options = {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
  }
  autoscaling_group_tags = {
    "AmazonECSManaged" = true
    "Name"             = each.value.asg_instance_name
  }

  tags = data.aws_default_tags.default.tags
}
