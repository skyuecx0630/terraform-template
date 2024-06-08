data "aws_iam_policy_document" "build_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["codebuild.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "deploy_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["codedeploy.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "pipeline_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["codepipeline.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "eventbridge_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["events.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "build_policy" {
  statement {
    sid = "logs"
    actions = [
      "logs:CreateLogStream",
      "logs:CreateLogGroup",
      "logs:PutLogEvents"
    ]
    resources = ["*"]
  }

  statement {
    sid = "s3"
    actions = [
      "s3:PutObject",
      "s3:GetObject",
      "s3:GetObjectVersion",
      "s3:GetBucketAcl",
      "s3:GetBucketLocation"
    ]
    resources = ["*"]
  }

  statement {
    sid       = "codecommit"
    actions   = ["codecommit:GitPull"]
    resources = ["*"]
  }

  statement {
    sid = "ecr"
    actions = [
      "ecr:BatchCheckLayerAvailability",
      "ecr:CompleteLayerUpload",
      "ecr:GetAuthorizationToken",
      "ecr:InitiateLayerUpload",
      "ecr:PutImage",
      "ecr:UploadLayerPart"
    ]
    resources = ["*"]
  }
}

data "aws_iam_policy_document" "deploy_policy" {
  statement {
    sid       = "RunInstance"
    actions   = ["ec2:RunInstances", "ec2:CreateTags"]
    resources = ["*"]
  }

  statement {
    sid       = "PassRole"
    actions   = ["iam:PassRole"]
    resources = ["*"]
  }
}

data "aws_iam_policy_document" "pipeline_policy" {
  statement {
    sid       = "passrole"
    actions   = ["iam:PassRole"]
    resources = ["*"]

    condition {
      test     = "StringEqualsIfExists"
      variable = "iam:PassedToService"

      values = ["ec2.amazonaws.com", "ecs-tasks.amazonaws.com"]
    }
  }

  statement {
    sid = "codecommit"
    actions = [
      "codecommit:CancelUploadArchive",
      "codecommit:GetBranch",
      "codecommit:GetCommit",
      "codecommit:GetRepository",
      "codecommit:GetUploadArchiveStatus",
      "codecommit:UploadArchive"
    ]
    resources = ["*"]
  }

  statement {
    sid = "codebuild"
    actions = [
      "codebuild:BatchGetBuilds",
      "codebuild:StartBuild"
    ]
    resources = ["*"]
  }

  statement {
    sid = "codedeploy"
    actions = [
      "codedeploy:CreateDeployment",
      "codedeploy:GetApplication",
      "codedeploy:GetApplicationRevision",
      "codedeploy:GetDeployment",
      "codedeploy:GetDeploymentConfig",
      "codedeploy:RegisterApplicationRevision"
    ]
    resources = ["*"]
  }

  statement {
    sid = "infrastructure"
    actions = [
      "ec2:*",
      "elasticloadbalancing:*",
      "autoscaling:*",
      "cloudwatch:*",
      "s3:*",
      "ecs:*"
    ]
    resources = ["*"]
  }
}

data "aws_iam_policy_document" "eventbridge_policy" {
  statement {
    sid       = "pipelineExecution"
    actions   = ["codepipeline:StartPipelineExecution"]
    resources = ["*"]
  }
}

resource "aws_iam_role" "build_role" {
  for_each = { for k, v in var.pipelines : k => v if v.codebuild_create }

  name = "codebuild-${each.value.codebuild_name}-role"

  assume_role_policy = data.aws_iam_policy_document.build_assume_role_policy.json
  inline_policy {
    name   = "codebuild-policy"
    policy = data.aws_iam_policy_document.build_policy.json
  }
}

resource "aws_iam_role" "deploy_role" {
  for_each = {
    for k, v in var.pipelines : k => v
    if v.platform == "ECS"
    && v.deploy_blue_green
    && v.codedeploy_create
    && v.deploy_stage
  }
  name = "codedeploy-${each.value.codedeploy_application_name}-role"

  assume_role_policy = data.aws_iam_policy_document.deploy_assume_role_policy.json

  inline_policy {
    name   = "codedeploy-policy"
    policy = data.aws_iam_policy_document.deploy_policy.json
  }

  managed_policy_arns = [
    "arn:aws:iam::aws:policy/service-role/AWSCodeDeployRole",
    "arn:aws:iam::aws:policy/AWSCodeDeployRoleForECS"
  ]
}

resource "aws_iam_role" "pipeline_role" {
  for_each = var.pipelines

  name = "codepipeline-${each.value.codepipeline_name}-role"

  assume_role_policy = data.aws_iam_policy_document.pipeline_assume_role_policy.json
  inline_policy {
    name   = "codepipeline-policy"
    policy = data.aws_iam_policy_document.pipeline_policy.json
  }
}

resource "aws_iam_role" "eventbridge_role" {
  for_each = var.pipelines

  name = "eventbridge-${each.value.codepipeline_name}-role"

  assume_role_policy = data.aws_iam_policy_document.eventbridge_assume_role_policy.json
  inline_policy {
    name   = "eventbridge-policy"
    policy = data.aws_iam_policy_document.eventbridge_policy.json
  }
}
