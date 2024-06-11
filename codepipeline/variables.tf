variable "pipelines" {
  type        = map(any)
  description = "Map for CodePipelines"

  default = {
    myapp = {
      codepipeline_name = "myapp-pipeline"
      platform          = "ECS" # 'ECS' only for now
      deploy_stage      = false
      deploy_blue_green = true

      artifact_bucket = "hmoon-pipeline-artifacts" # Only existing bucket

      codecommit_create         = true
      codecommit_name           = "myapp"
      codecommit_default_branch = "main"

      codebuild_create              = true
      codebuild_name                = "myapp-build"
      codebuild_ecr_repository_name = "myapp"

      codedeploy_ecs_cluster_name = "skills-cluster"
      codedeploy_ecs_service_name = "myapp"

      # Only for Blue/Green
      codedeploy_create                = true
      codedeploy_application_name      = "myapp-deploy"
      codedeploy_deployment_group_name = "myapp-dg"

      codedeploy_ecs_listener_arn        = "arn:aws:elasticloadbalancing:us-east-1:856210586235:listener/app/myapp-alb/18ac23c1e9907228/5cc19c4b2434ce82"
      codedeploy_ecs_target_group_1_name = "myapp-tg"
      codedeploy_ecs_target_group_2_name = "myapp-tg-2"
    }
  }
}
