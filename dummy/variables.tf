variable "dummy" {
  type        = any
  description = "Map for dummy resources"

  default = {
    vpc = true
    s3  = true

    alb        = true
    asg        = true
    cloudfront = true
    waf        = true
    apigateway = true
    ecr        = true

    rds   = true
    cache = true
    docdb = true
    ddb   = true
    efs   = true

    config    = true
    guardduty = true
    inspector = true
    macie     = true
  }
}
