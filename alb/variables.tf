variable "alb" {
  type        = map(any)
  description = "Map for ALB"

  default = {
    alb = {
      name     = "skills-myapp-alb"
      internal = false

      waf_enabled      = true
      waf_monitor_mode = true

      enable_access_logs = true
      access_logs_bucket = "hmoon-logs" # SSE-S3, access logs policy attached
      access_logs_prefix = ""           # bucket policy should be modified

      listener_port      = 80
      security_group_ids = ["sg-031d554f7b570ee73"]
      subnet_ids         = ["subnet-09b43b80cfa72c577", "subnet-00c324cceaff70f59"]
    }
  }
}

variable "target_group" {
  type        = map(any)
  description = "Map for target group"

  default = {
    myapp1 = {
      name        = "skills-myapp-tg"
      target_type = "ip" # instance or ip
      vpc_id      = "vpc-0ece3b0f4e007c367"

      port                 = 8080
      deregistration_delay = 10

      health_check_port                = 8080
      health_check_path                = "/health"
      health_check_healthy_threshold   = 2
      health_check_unhealthy_threshold = 2
      health_check_interval            = 10
      health_check_timeout             = 5
    }
  }
}
