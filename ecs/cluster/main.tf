module "ecs_cluster" {
  source = "terraform-aws-modules/ecs/aws"

  cluster_name = var.cluster_name

  default_capacity_provider_use_fargate = var.use_fargate

  fargate_capacity_providers = (var.use_fargate ? {
    FARGATE = {
      default_capacity_provider_strategy = {
        weight = 50
        base   = 20
      }
    }
  } : {})

  autoscaling_capacity_providers = var.use_fargate ? {} : {
    asg = {
      auto_scaling_group_arn = module.asg.autoscaling_group_arn

      managed_scaling = {
        maximum_scaling_step_size = 8
        minimum_scaling_step_size = 1
        status                    = "ENABLED"
        target_capacity           = 80
      }
    }
  }

}

###########################################################
# Auto scaling group
###########################################################

data "aws_ssm_parameter" "ecs_optimized_ami" {
  name = "/aws/service/ecs/optimized-ami/amazon-linux-2/recommended"
}

module "asg" {
  source  = "terraform-aws-modules/autoscaling/aws"
  version = "~> 7.6"
  create  = !var.use_fargate

  name = var.asg_name

  desired_capacity = 2
  min_size         = 2
  max_size         = 8

  image_id      = jsondecode(data.aws_ssm_parameter.ecs_optimized_ami.value)["image_id"]
  instance_type = var.instance_type

  user_data = base64encode(
    <<-EOT
      #!/bin/bash

      cat <<'EOF' >> /etc/ecs/ecs.config
      ECS_CLUSTER=${var.cluster_name}
      ECS_LOGLEVEL=debug
      EOF
    EOT
  )
  ignore_desired_capacity_changes = false

  create_iam_instance_profile = !var.use_fargate
  iam_role_name               = "${var.instance_name}-role"
  iam_role_policies = {
    AmazonEC2ContainerServiceforEC2Role = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
    AmazonSSMManagedInstanceCore        = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  }

  autoscaling_group_tags = {
    AmazonECSManaged = true
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
    http_put_response_hop_limit = 2
  }

  tag_specifications = [
    {
      resource_type = "instance"
      tags = {
        "Name" = var.instance_name
      }
    }
  ]
}
