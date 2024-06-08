data "aws_region" "region" {}
data "aws_partition" "partition" {}
data "aws_caller_identity" "account" {}

resource "aws_codepipeline" "pipeline" {
  for_each = var.pipelines

  name     = each.value.codepipeline_name
  role_arn = aws_iam_role.pipeline_role[each.key].arn

  artifact_store {
    type     = "S3"
    location = each.value.artifact_bucket
  }

  stage {
    name = "Source"
    action {
      name = "SourceAction"

      category = "Source"
      owner    = "AWS"
      provider = "CodeCommit"
      version  = "1"

      configuration = {
        RepositoryName       = each.value.codecommit_name
        BranchName           = each.value.codecommit_default_branch
        PollForSourceChanges = false
      }
      output_artifacts = ["SourceArtifact"]
    }
  }
  stage {
    name = "Build"
    action {
      name = "BuildAction"

      category = "Build"
      owner    = "AWS"
      provider = "CodeBuild"
      version  = "1"

      configuration = {
        ProjectName = each.value.codebuild_name
      }
      input_artifacts  = ["SourceArtifact"]
      output_artifacts = ["BuildArtifact"]
    }
  }
  dynamic "stage" {
    for_each = each.value.deploy_stage ? [1] : []

    content {
      name = "Deploy"
      action {
        name = "DeployAction"

        category = "Deploy"
        owner    = "AWS"
        provider = each.value.deploy_blue_green ? "CodeDeployToECS" : "ECS"
        version  = "1"

        configuration = each.value.deploy_blue_green ? {
          ApplicationName                = each.value.codedeploy_application_name
          DeploymentGroupName            = each.value.codedeploy_deployment_group_name
          TaskDefinitionTemplateArtifact = "BuildArtifact"
          AppSpecTemplateArtifact        = "BuildArtifact"
          Image1ArtifactName             = "BuildArtifact"
          Image1ContainerName            = "IMAGE1_NAME"
          } : {
          ClusterName = each.value.codedeploy_ecs_cluster_name
          ServiceName = each.value.codedeploy_ecs_service_name
          FileName    = "imagedefinitions.json"
        }
        input_artifacts = ["BuildArtifact"]
      }
    }
  }
}

resource "aws_codecommit_repository" "codecommit_repository" {
  for_each = { for k, v in var.pipelines : k => v if v.codecommit_create }

  repository_name = each.value.codecommit_name
  default_branch  = each.value.codecommit_default_branch
}

resource "aws_codebuild_project" "ecs_codebuild_project" {
  for_each = { for k, v in var.pipelines : k => v if v.codebuild_create && v.platform == "ECS" }

  name = each.value.codebuild_name
  environment {
    compute_type    = "BUILD_GENERAL1_SMALL"
    image           = "aws/codebuild/amazonlinux2-x86_64-standard:4.0"
    type            = "LINUX_CONTAINER"
    privileged_mode = true
    environment_variable {
      name  = "IMAGE_REPO_NAME"
      type  = "PLAINTEXT"
      value = each.value.codebuild_ecr_repository_name
    }
  }

  source {
    type     = "CODECOMMIT"
    location = "https://git-codecommit.${data.aws_region.region.name}.amazonaws.com/v1/repos/${each.value.codecommit_name}"
  }
  source_version = "refs/heads/${each.value.codecommit_default_branch}"

  artifacts {
    type = "NO_ARTIFACTS"
  }

  logs_config {
    cloudwatch_logs {
      status = "ENABLED"
    }
  }

  service_role = aws_iam_role.build_role[each.key].arn
}

resource "aws_codedeploy_app" "ecs_codedeploy_application" {
  for_each = {
    for k, v in var.pipelines : k => v
    if v.platform == "ECS"
    && v.deploy_blue_green
    && v.codedeploy_create
    && v.deploy_stage
  }

  name             = each.value.codedeploy_application_name
  compute_platform = "ECS"
}

resource "aws_codedeploy_deployment_group" "ecs_codedeploy_deployment_group" {
  for_each = {
    for k, v in var.pipelines : k => v
    if v.platform == "ECS"
    && v.deploy_blue_green
    && v.codedeploy_create
    && v.deploy_stage
  }

  app_name              = each.value.codedeploy_application_name
  deployment_group_name = each.value.codedeploy_deployment_group_name
  service_role_arn      = aws_iam_role.deploy_role[each.key].arn

  ecs_service {
    cluster_name = each.value.codedeploy_ecs_cluster_name
    service_name = each.value.codedeploy_ecs_service_name
  }
  load_balancer_info {
    target_group_pair_info {
      prod_traffic_route {
        listener_arns = [each.value.codedeploy_ecs_listener_arn]
      }
      target_group {
        name = each.value.codedeploy_ecs_target_group_1_name
      }
      target_group {
        name = each.value.codedeploy_ecs_target_group_2_name
      }
    }
  }
  deployment_style {
    deployment_option = "WITH_TRAFFIC_CONTROL"
    deployment_type   = "BLUE_GREEN"
  }
  blue_green_deployment_config {
    deployment_ready_option {
      action_on_timeout = "CONTINUE_DEPLOYMENT"
    }
    terminate_blue_instances_on_deployment_success {
      action                           = "TERMINATE"
      termination_wait_time_in_minutes = 0
    }
  }
  deployment_config_name = "CodeDeployDefault.ECSAllAtOnce"
  auto_rollback_configuration {
    enabled = true
    events  = ["DEPLOYMENT_FAILURE"]
  }
}

resource "aws_cloudwatch_event_rule" "eventbridge_rule" {
  for_each = var.pipelines

  event_pattern = jsonencode({
    source      = ["aws.codecommit"]
    detail-type = ["CodeCommit Repository State Change"]
    resources   = ["arn:${data.aws_partition.partition.id}:codecommit:${data.aws_region.region.name}:${data.aws_caller_identity.account.account_id}:${each.value.codecommit_name}"]
    detail = {
      event         = ["referenceCreated", "referenceUpdated"]
      referenceName = ["main"]
      referenceType = ["branch"]
    }
  })
}

resource "aws_cloudwatch_event_target" "name" {
  for_each = var.pipelines

  rule     = aws_cloudwatch_event_rule.eventbridge_rule[each.key].name
  arn      = "arn:${data.aws_partition.partition.id}:codepipeline:${data.aws_region.region.name}:${data.aws_caller_identity.account.account_id}:${each.value.codepipeline_name}"
  role_arn = aws_iam_role.eventbridge_role[each.key].arn
}
