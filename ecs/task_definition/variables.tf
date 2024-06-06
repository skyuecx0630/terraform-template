variable "region" {
  type        = string
  description = "AWS region"
  default     = "us-east-1"
}

variable "task_definitions" {
  type        = map(any)
  description = "Map for ECS task definitions"

  default = {
    testapp = {
      family                   = "testapp"
      requires_compatibilities = ["FARGATE"]

      cpu    = 256
      memory = 512
      container_definitions = [
        {
          name             = "testapp"
          image            = "hmoon630/sample-fastapi"
          port             = 8080
          healthcheck_path = "/health"
          environment      = []
        },
        {
          name             = "sampler"
          image            = "public.ecr.aws/g1s2t7w5/sampler:latest"
          port             = 8888
          healthcheck_path = "/dummy/health"
          environment = [
            {
              name  = "PORT"
              value = "8888"
            },
            {
              name  = "UPSTREAM_ENDPOINT"
              value = "http://localhost:8080"
            },
            {
              name  = "IGNORE_PATH"
              value = "/favicon.ico"
            },
            {
              name  = "IGNORE_HEALTHCHECK"
              value = "1"
            }
          ]
        }
      ]
    }
  }
}
