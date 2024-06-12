resource "aws_ecs_service" "service" {
  for_each = var.services

  cluster = each.value.cluster_name
  name    = each.value.service_name

  task_definition = each.value.task_definition

  network_configuration {
    assign_public_ip = each.value.assign_public_ip
    security_groups  = each.value.security_groups
    subnets          = each.value.subnets
  }

  dynamic "load_balancer" {
    for_each = try(each.value.load_balancer, [])
    content {
      target_group_arn = load_balancer.value.target_group_arn
      container_name   = load_balancer.value.container_name
      container_port   = load_balancer.value.container_port
    }
  }

  capacity_provider_strategy {
    base              = 0
    capacity_provider = each.value.capacity_provider
    weight            = 100
  }
  dynamic "ordered_placement_strategy" {
    for_each = each.value.capacity_provider == "FARGATE" ? [] : [
      {
        type  = "spread"
        field = "instanceId"
      },
      {
        type  = "spread"
        field = "attribute:ecs.availability-zone"
      }
    ]
    content {
      type  = ordered_placement_strategy.value.type
      field = ordered_placement_strategy.value.field
    }
  }

  deployment_maximum_percent         = 200
  deployment_minimum_healthy_percent = 100
  deployment_controller {
    type = each.value.deployment_controller
  }
  dynamic "deployment_circuit_breaker" {
    for_each = each.value.deployment_controller == "ECS" ? [1] : []
    content {
      enable   = true
      rollback = true
    }
  }

  dynamic "service_registries" {
    for_each = try(each.value.service_registry_arn, "") != "" ? [1] : []
    content {
      registry_arn = each.value.service_registry_arn
    }
  }
  enable_execute_command = each.value.enable_ecs_exec
}

resource "aws_appautoscaling_target" "scaling_target" {
  for_each = { for k, v in var.services : k => v if v.enable_scaling }
  # depends_on = [aws_ecs_service.service[each.key]]

  service_namespace  = "ecs"
  scalable_dimension = "ecs:service:DesiredCount"
  resource_id        = "service/${each.value.cluster_name}/${each.value.service_name}"

  min_capacity = 2
  max_capacity = 10
}

resource "aws_appautoscaling_policy" "scaling_policy" {
  for_each = { for k, v in var.services : k => v if v.enable_scaling }

  name = "${each.value.service_name}-cluster-scaling"

  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.scaling_target[each.key].resource_id
  scalable_dimension = aws_appautoscaling_target.scaling_target[each.key].scalable_dimension
  service_namespace  = aws_appautoscaling_target.scaling_target[each.key].service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }

    target_value = 60
  }
}
