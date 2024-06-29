data "aws_ec2_managed_prefix_list" "cloudfront" {
  name = "com.amazonaws.global.cloudfront.origin-facing"
}

data "aws_ami" "al2023_ami" {
  most_recent = true

  owners = ["amazon"]
  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-x86_64"]
  }
}

# ==================================================
# ALB
# ==================================================

resource "aws_lb" "alb" {
  count = var.dummy.alb ? 1 : 0

  name               = "dummy-alb"
  load_balancer_type = "application"
  internal           = false

  subnets         = module.vpc[0].public_subnets
  security_groups = [aws_security_group.alb_sg[0].id]

  enable_cross_zone_load_balancing = true
  enable_http2                     = true

  access_logs {
    enabled = true
    bucket  = module.s3_bucket[0].s3_bucket_id
    prefix  = "alb"
  }
}

resource "aws_security_group" "alb_sg" {
  count = var.dummy.alb ? 1 : 0
  name  = "dummy-alb-sg"

  vpc_id = module.vpc[0].vpc_id

  ingress {
    protocol    = "tcp"
    from_port   = 80
    to_port     = 80
    description = "from CloudFront"

    prefix_list_ids = [data.aws_ec2_managed_prefix_list.cloudfront.id]
  }

  egress {
    protocol  = "-1"
    from_port = 0
    to_port   = 0

    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_lb_listener" "alb_listener" {
  count = var.dummy.alb ? 1 : 0

  load_balancer_arn = aws_lb.alb[0].arn

  protocol = "HTTP"
  port     = 80

  default_action {
    type = "fixed-response"
    fixed_response {
      content_type = "text/plain"
      message_body = "Not found"
      status_code  = "404"
    }
  }
}

resource "aws_lb_target_group" "alb_target_group" {
  count = var.dummy.alb ? 1 : 0

  name        = "dummy-tg"
  target_type = "instance"

  ip_address_type  = "ipv4"
  protocol         = "HTTP"
  protocol_version = "HTTP1"

  port                 = 8080
  deregistration_delay = 10

  vpc_id = module.vpc[0].vpc_id

  health_check {
    protocol = "HTTP"
    port     = 8080
    path     = "/health"

    healthy_threshold   = 2
    unhealthy_threshold = 2
    interval            = 5
    timeout             = 3
  }
}

resource "aws_lb_listener_rule" "alb_listener_rule" {
  count = var.dummy.alb ? 1 : 0

  listener_arn = aws_lb_listener.alb_listener[0].arn
  priority     = 1

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.alb_target_group[0].arn
  }

  condition {
    path_pattern {
      values = ["/*"]
    }
  }
}

# ==================================================
# ASG
# ==================================================

resource "aws_security_group" "asg_sg" {
  count = var.dummy.asg ? 1 : 0
  name  = "dummy-asg-sg"

  vpc_id = module.vpc[0].vpc_id

  ingress {
    protocol    = "tcp"
    from_port   = 8080
    to_port     = 8080
    description = "from ALB"

    security_groups = [aws_security_group.alb_sg[0].id]
  }

  egress {
    protocol  = "-1"
    from_port = 0
    to_port   = 0

    cidr_blocks = ["0.0.0.0/0"]
  }
}

module "asg" {
  source  = "terraform-aws-modules/autoscaling/aws"
  version = "~> 7.6"

  count      = var.dummy.asg ? 1 : 0
  depends_on = [aws_lb_listener_rule.alb_listener_rule[0]]

  name = "dummy-asg"

  image_id      = data.aws_ami.al2023_ami.image_id
  instance_type = "t3.medium"

  user_data = base64encode(<<EOT
    #!/bin/bash -x

    yum install -y docker
    systemctl enable --now docker
    usermod -aG docker ec2-user

    docker run -d --name sample-app --restart always --pull always -p 8080:8080 hmoon630/sample-fastapi:latest
    EOT
  )

  min_size                        = 0
  max_size                        = 2
  desired_capacity                = 0
  ignore_desired_capacity_changes = true
  update_default_version          = true
  wait_for_capacity_timeout       = 0

  vpc_zone_identifier = module.vpc[0].private_subnets
  security_groups     = [aws_security_group.asg_sg[0].id]
  target_group_arns   = [aws_lb_target_group.alb_target_group[0].arn]

  scaling_policies = {
    avg-cpu-policy-greater-than-50 = {
      policy_type = "TargetTrackingScaling"
      target_tracking_configuration = {
        predefined_metric_specification = {
          predefined_metric_type = "ASGAverageCPUUtilization"
        }
        target_value = 60
      }
    }
  }


  enable_monitoring = true
  block_device_mappings = [
    {
      # Root volume
      device_name = "/dev/xvda"
      no_device   = 0
      ebs = {
        delete_on_termination = true
        encrypted             = true
        volume_size           = 20
        volume_type           = "gp3"
      }
    }
  ]
  metadata_options = {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 2
  }

  enabled_metrics = [
    "GroupDesiredCapacity",
    "GroupInServiceCapacity",
    "GroupPendingCapacity",
    "GroupMinSize",
    "GroupMaxSize",
    "GroupInServiceInstances",
    "GroupPendingInstances",
    "GroupStandbyInstances",
    "GroupStandbyCapacity",
    "GroupTerminatingCapacity",
    "GroupTerminatingInstances",
    "GroupTotalCapacity",
    "GroupTotalInstances"
  ]

  tag_specifications = [
    {
      resource_type = "instance"
      tags = {
        "Name" = "dummy-instance"
      }
    }
  ]

  tags = data.aws_default_tags.default.tags
}

# ==================================================
# CloudFront
# ==================================================

resource "aws_cloudfront_distribution" "cloudfront" {
  count = var.dummy.cloudfront ? 1 : 0

  enabled = true

  web_acl_id = aws_wafv2_web_acl.waf_acl[0].arn

  origin {
    domain_name = aws_lb.alb[0].dns_name
    origin_id   = aws_lb.alb[0].dns_name
    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "http-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }
  }

  default_cache_behavior {
    allowed_methods        = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = aws_lb.alb[0].dns_name
    viewer_protocol_policy = "redirect-to-https"

    # Cache policy: CachingDisabled
    cache_policy_id = "4135ea2d-6df8-44a3-9df3-4b5a84be39ad"
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }
}


resource "aws_wafv2_web_acl" "waf_acl" {
  count = var.dummy.waf ? 1 : 0

  name  = "dummy-cloudfront-acl"
  scope = "CLOUDFRONT"

  default_action {
    allow {}
  }

  visibility_config {
    sampled_requests_enabled   = true
    cloudwatch_metrics_enabled = true
    metric_name                = "dummy-cloudfront-metric"
  }

  dynamic "rule" {
    for_each = {
      for i, r in [
        "AWSManagedRulesAmazonIpReputationList",
        "AWSManagedRulesCommonRuleSet",
        "AWSManagedRulesKnownBadInputsRuleSet",
      ] : i => r
    }

    content {
      name     = rule.value
      priority = rule.key

      override_action {
        none {}
      }

      statement {
        managed_rule_group_statement {
          vendor_name = "AWS"
          name        = rule.value
        }
      }
      visibility_config {
        sampled_requests_enabled   = true
        cloudwatch_metrics_enabled = true
        metric_name                = "AWS-${rule.value}"
      }
    }
  }
}

# ==================================================
# ECR
# ==================================================

resource "aws_ecr_repository" "repository" {
  count = var.dummy.ecr ? 1 : 0

  name         = "dummy"
  force_delete = true

  encryption_configuration {
    encryption_type = "KMS"
    kms_key         = module.kms_key[0].key_arn
  }


  image_scanning_configuration {
    scan_on_push = true
  }

  image_tag_mutability = "IMMUTABLE"
}

# ==================================================
# API GW
# ==================================================

resource "aws_api_gateway_rest_api" "rest_api" {
  count = var.dummy.apigateway ? 1 : 0

  name = "dummy-rest-api"

  endpoint_configuration {
    types = ["REGIONAL"]
  }
}
