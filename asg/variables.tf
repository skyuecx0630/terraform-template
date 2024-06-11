variable "asg" {
  type        = map(any)
  description = "Map for ASG"

  default = {
    asg = {
      name          = "skills-myapp"
      instance_name = "skills-myapp"

      ami_id        = "ami-01bc990364452ab3e"
      instance_type = "t3.medium"
      key_pair      = null
      iam_role_name = null # "skills-myapp-role"

      enable_user_data = true
      user_data_path   = "./userdata.sh"

      min_size = 2
      max_size = 10

      subnet_ids         = ["subnet-06a6897f1cc19ddf3", "subnet-025da93873dadf2c2"]
      security_group_ids = ["sg-0ced96d3a74f24979"]

      health_check_type = "EC2" # "EC2" or "ELB"
      target_group_arns = [
        "arn:aws:elasticloadbalancing:us-east-1:856210586235:targetgroup/skills-myapp-tg/87a03cc0b3164bff",
        "arn:aws:elasticloadbalancing:us-east-1:856210586235:targetgroup/skills-myapp-sampling-tg/a0c498a69edaff8d"
      ]

      # Set 0 to disable target tracking
      target_tracking_cpu_util                 = 60
      target_tracking_request_count_per_target = 60 # (60 / average_processing_time) * queue_size * 60%
      # "${alb.arn_suffix}/${target_group.arn_suffix}"
      target_tracking_resource_label = "app/skills-myapp-alb/5fcd109c6f1a1511/targetgroup/skills-myapp-tg/87a03cc0b3164bff"
    }
  }
}
