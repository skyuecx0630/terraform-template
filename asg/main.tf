data "aws_default_tags" "default" {}

module "asg" {
  source  = "terraform-aws-modules/autoscaling/aws"
  version = "~> 7.6"

  for_each = var.asg

  name = each.value.name

  image_id      = each.value.ami_id
  instance_type = each.value.instance_type

  key_name = each.value.key_pair

  create_iam_instance_profile = each.value.iam_role_name != null ? false : true
  iam_role_name               = each.value.iam_role_name != null ? each.value.iam_role_name : "${each.value.name}-role"
  iam_role_policies = {
    AmazonSSMManagedInstanceCore  = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
    CloudWatchAgentServerPolicy   = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
    AmazonEC2RoleforAWSCodeDeploy = "arn:aws:iam::aws:policy/service-role/AmazonEC2RoleforAWSCodeDeploy"
  }

  user_data = each.value.enable_user_data ? base64encode(file(each.value.user_data_path)) : null

  min_size                        = each.value.min_size
  max_size                        = each.value.max_size
  ignore_desired_capacity_changes = true
  update_default_version          = true
  wait_for_capacity_timeout       = 0

  vpc_zone_identifier = each.value.subnet_ids
  security_groups     = each.value.security_group_ids

  health_check_type         = each.value.health_check_type
  health_check_grace_period = 60
  target_group_arns         = each.value.target_group_arns

  scaling_policies = merge(
    try(each.value.target_tracking_cpu_util, 0) != 0 ? {
      avg-cpu-policy-greater-than-50 = {
        policy_type = "TargetTrackingScaling"
        target_tracking_configuration = {
          predefined_metric_specification = {
            predefined_metric_type = "ASGAverageCPUUtilization"
          }
          target_value = each.value.target_tracking_cpu_util
        }
      }
    } : {},
    try(each.value.target_tracking_request_count_per_target, 0) != 0 ? {
      request-count-per-target = {
        policy_type = "TargetTrackingScaling"
        target_tracking_configuration = {
          predefined_metric_specification = {
            predefined_metric_type = "ALBRequestCountPerTarget"
            resource_label         = each.value.target_tracking_resource_label
          }
          target_value = each.value.target_tracking_request_count_per_target
        }
      }
    } : {}
  )

  enable_monitoring = true
  block_device_mappings = [
    {
      # Root volume
      device_name = "/dev/xvda"
      no_device   = 0
      ebs = {
        delete_on_termination = true
        encrypted             = true
        volume_size           = 100
        volume_type           = "gp3"
      }
    }
  ]
  metadata_options = {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 2
  }

  enabled_metrics = [
    "GroupDesiredCapacity",
    "GroupInServiceCapacity",
    "GroupPendingCapacity",
    "GroupMinSize",
    "GroupMaxSize",
    "GroupInServiceInstances",
    "GroupPendingInstances",
    "GroupStandbyInstances",
    "GroupStandbyCapacity",
    "GroupTerminatingCapacity",
    "GroupTerminatingInstances",
    "GroupTotalCapacity",
    "GroupTotalInstances"
  ]

  tag_specifications = [
    {
      resource_type = "instance"
      tags = {
        "Name" = each.value.instance_name
      }
    }
  ]

  tags = data.aws_default_tags.default.tags
}
