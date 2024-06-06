variable "services" {
  type        = map(any)
  description = "Map for ECS services' configuration"

  default = {
    myapp = {
      cluster_name          = "skills-cluster"
      service_name          = "myapp"
      task_definition       = "myapp"
      capacity_provider     = "FARGATE"
      deployment_controller = "ECS"

      enable_ecs_exec      = false
      enable_scaling       = true
      service_registry_arn = "arn:aws:servicediscovery:us-east-1:856210586235:service/srv-3ynttnapu3bbspms"

      assign_public_ip = false
      security_groups  = ["sg-01a7d0d191e791f3d"]
      subnets          = ["subnet-0227c0887f7f841f0", "subnet-0f3d271ec01045dd3"]

      load_balancer = [
        {
          target_group_arn = "arn:aws:elasticloadbalancing:us-east-1:856210586235:targetgroup/product-tg/3dea3992b003bf5d"
          container_name   = "myapp"
          container_port   = 8080
        },
        {
          target_group_arn = "arn:aws:elasticloadbalancing:us-east-1:856210586235:targetgroup/product-sampling-tg/7dcec07a01796142"
          container_name   = "sampler"
          container_port   = 8888
        }
      ]
    }
  }
}
