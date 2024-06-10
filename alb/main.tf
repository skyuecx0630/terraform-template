resource "aws_lb" "alb" {
  for_each = var.alb

  name               = each.value.name
  load_balancer_type = "application"
  internal           = each.value.internal

  subnets         = each.value.subnet_ids
  security_groups = each.value.security_group_ids

  enable_cross_zone_load_balancing = true
  enable_http2                     = true

  access_logs {
    enabled = each.value.enable_access_logs
    bucket  = each.value.access_logs_bucket
    prefix  = each.value.access_logs_prefix != "" ? each.value.access_logs_prefix : null
  }
}

resource "aws_lb_listener" "alb_listener" {
  for_each = var.alb

  load_balancer_arn = aws_lb.alb[each.key].arn

  protocol = "HTTP"
  port     = each.value.listener_port

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
  for_each = var.target_group

  name        = each.value.name
  target_type = each.value.target_type

  ip_address_type  = "ipv4"
  protocol         = "HTTP"
  protocol_version = "HTTP1"

  port                 = each.value.port
  deregistration_delay = each.value.deregistration_delay

  vpc_id = each.value.vpc_id

  health_check {
    protocol = "HTTP"
    port     = each.value.health_check_port
    path     = each.value.health_check_path

    healthy_threshold   = each.value.health_check_healthy_threshold
    unhealthy_threshold = each.value.health_check_unhealthy_threshold
    interval            = each.value.health_check_interval
    timeout             = each.value.health_check_timeout
  }
}

resource "aws_wafv2_web_acl" "waf_acl" {
  for_each = { for k, v in var.alb : k => v if v.waf_enabled }

  name  = "${each.value.name}-acl"
  scope = "REGIONAL"
  default_action {
    allow {

    }
  }
  visibility_config {
    sampled_requests_enabled   = true
    cloudwatch_metrics_enabled = true
    metric_name                = "${each.value.name}-metric"
  }

  rule {
    name     = "AWS-AWSManagedRulesAmazonIpReputationList"
    priority = 0
    override_action {
      dynamic "count" {
        for_each = each.value.waf_monitor_mode ? [1] : []
        content {}
      }
      dynamic "none" {
        for_each = each.value.waf_monitor_mode ? [] : [1]
        content {}
      }
    }

    statement {
      managed_rule_group_statement {
        vendor_name = "AWS"
        name        = "AWSManagedRulesAmazonIpReputationList"
      }
    }
    visibility_config {
      sampled_requests_enabled   = true
      cloudwatch_metrics_enabled = true
      metric_name                = "AWS-AWSManagedRulesAmazonIpReputationList"
    }
  }

  rule {
    name     = "AWS-AWSManagedRulesCommonRuleSet"
    priority = 1
    override_action {
      dynamic "count" {
        for_each = each.value.waf_monitor_mode ? [1] : []
        content {}
      }
      dynamic "none" {
        for_each = each.value.waf_monitor_mode ? [] : [1]
        content {}
      }
    }

    statement {
      managed_rule_group_statement {
        vendor_name = "AWS"
        name        = "AWSManagedRulesCommonRuleSet"
      }
    }
    visibility_config {
      sampled_requests_enabled   = true
      cloudwatch_metrics_enabled = true
      metric_name                = "AWS-AWSManagedRulesCommonRuleSet"
    }
  }

  rule {
    name     = "AWS-AWSManagedRulesKnownBadInputsRuleSet"
    priority = 2
    override_action {
      dynamic "count" {
        for_each = each.value.waf_monitor_mode ? [1] : []
        content {}
      }
      dynamic "none" {
        for_each = each.value.waf_monitor_mode ? [] : [1]
        content {}
      }
    }

    statement {
      managed_rule_group_statement {
        vendor_name = "AWS"
        name        = "AWSManagedRulesKnownBadInputsRuleSet"
      }
    }
    visibility_config {
      sampled_requests_enabled   = true
      cloudwatch_metrics_enabled = true
      metric_name                = "AWS-AWSManagedRulesKnownBadInputsRuleSet"
    }
  }
}

resource "aws_wafv2_web_acl_association" "waf_acl_association" {
  for_each = { for k, v in var.alb : k => v if v.waf_enabled }

  resource_arn = aws_lb.alb[each.key].arn
  web_acl_arn  = aws_wafv2_web_acl.waf_acl[each.key].arn
}
