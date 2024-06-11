variable "vpc_id" {
  type        = string
  description = "VPC id for security groups"
  default     = "vpc-0563dbe7d85595c5e"
}

variable "preset" {
  type        = any
  description = "Security group presets"

  default = {
    alb = {
      name = "skills-alb-sg"
      port = 80 # listener port

      cloudfront_only = true # restrict via prefix list
    }
    app = {
      name = "skills-app-sg"
      port = 8080
    }
    rds = {
      name = "skills-rds-sg"
      port = 3306
    }
  }
}

variable "security_group" {
  type        = map(any)
  description = "Map for security group"

  default = {
    skills-docdb-sg = { enable_egress = false }
    skills-cache-sg = { enable_egress = false }
  }
}
