resource "aws_ecs_task_definition" "task_definition" {
  for_each = var.task_definitions

  family                   = each.value.family
  requires_compatibilities = each.value.requires_compatibilities

  cpu          = each.value.cpu
  memory       = each.value.memory
  network_mode = "awsvpc"

  execution_role_arn = aws_iam_role.task_execution_role[each.key].arn
  task_role_arn      = aws_iam_role.task_role[each.key].arn

  container_definitions = jsonencode([for k, v in each.value.container_definitions : {
    name      = v.name
    image     = v.image
    essential = true
    portMappings = [
      {
        containerPort = v.port
        hostPort      = v.port
      }
    ]
    healthcheck = {
      command = ["CMD-SHELL", "curl -f http://localhost:${v.port}${v.healthcheck_path} || exit 1"]
    }
    logConfiguration = {
      logDriver = "awslogs"
      options = {
        awslogs-group         = aws_cloudwatch_log_group.log_group[each.key].name
        awslogs-region        = var.region
        awslogs-stream-prefix = v.name
        awslogs-create-group  = "true"
      }
    }
    environment = v.environment
  }])
}

data "aws_iam_policy_document" "ecs_task_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "task_execution_role" {
  for_each = var.task_definitions

  name = "${each.value.family}-execution-role"

  assume_role_policy = data.aws_iam_policy_document.ecs_task_assume_role_policy.json
  managed_policy_arns = [
    "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy",
    "arn:aws:iam::aws:policy/service-role/AWSAppSyncPushToCloudWatchLogs"
  ]
}

resource "aws_iam_role" "task_role" {
  for_each = var.task_definitions

  name = "${each.value.family}-role"

  assume_role_policy = data.aws_iam_policy_document.ecs_task_assume_role_policy.json
}

resource "aws_cloudwatch_log_group" "log_group" {
  for_each = var.task_definitions

  name = "/ecs/application/${each.value.family}"

  retention_in_days = 14
}
