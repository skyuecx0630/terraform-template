locals {
  methods = {
    GET  = ["GET", "HEAD"]
    POST = ["GET", "HEAD", "OPTIONS", "PUT", "POST", "PATCH", "DELETE"]
  }
}

resource "aws_cloudfront_distribution" "distribution" {
  for_each = var.distribution

  enabled             = true
  is_ipv6_enabled     = each.value.enable_ipv6
  default_root_object = each.value.default_root_object

  web_acl_id = each.value.enable_waf ? aws_wafv2_web_acl.waf_acl[each.key].arn : null

  dynamic "logging_config" {
    for_each = each.value.log_bucket != null ? [1] : []
    content {
      bucket          = each.value.log_bucket
      include_cookies = false
      prefix          = each.value.log_prefix
    }
  }

  dynamic "origin" {
    for_each = each.value.custom_origins
    content {
      origin_id   = origin.key
      domain_name = origin.value.domain_name

      connection_attempts = origin.value.retry
      connection_timeout  = origin.value.connection_timeout
      custom_origin_config {
        http_port                = 80
        https_port               = 443
        origin_keepalive_timeout = 5
        origin_protocol_policy   = origin.value.protocol
        origin_read_timeout      = origin.value.read_timeout
        origin_ssl_protocols     = ["TLSv1.2", "TLSv1.1", "TLSv1", "SSLv3"]
      }
    }
  }

  dynamic "origin" {
    for_each = each.value.s3_origins
    content {
      origin_id   = origin.key
      domain_name = origin.value.domain_name
      s3_origin_config {
        origin_access_identity = ""
      }
      origin_access_control_id = aws_cloudfront_origin_access_control.oac.id
    }
  }

  default_cache_behavior {
    target_origin_id         = each.value.default_cache_behavior.origin_id
    viewer_protocol_policy   = "redirect-to-https"
    allowed_methods          = local.methods[each.value.default_cache_behavior.allowed_methods]
    cached_methods           = ["GET", "HEAD"]
    cache_policy_id          = each.value.default_cache_behavior.cache_policy_id
    origin_request_policy_id = each.value.default_cache_behavior.origin_request_policy_id
  }

  dynamic "ordered_cache_behavior" {
    for_each = each.value.cache_behavior
    content {
      path_pattern             = ordered_cache_behavior.value.path_pattern
      target_origin_id         = ordered_cache_behavior.value.origin_id
      viewer_protocol_policy   = "redirect-to-https"
      allowed_methods          = local.methods[ordered_cache_behavior.value.allowed_methods]
      cached_methods           = ["GET", "HEAD"]
      cache_policy_id          = ordered_cache_behavior.value.cache_policy_id
      origin_request_policy_id = ordered_cache_behavior.value.origin_request_policy_id
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }
  restrictions {
    geo_restriction {
      restriction_type = "none"
      locations        = []
    }
  }
}

resource "aws_cloudfront_origin_access_control" "oac" {
  name                              = "s3_oac"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

resource "aws_wafv2_web_acl" "waf_acl" {
  for_each = { for k, v in var.distribution : k => v if v.enable_waf }

  name  = "${each.value.name}-acl"
  scope = "CLOUDFRONT"
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
