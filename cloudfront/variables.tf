variable "distribution" {
  type = any
  default = {
    cdn = {
      name = "skills-cdn"

      enable_ipv6         = false
      default_root_object = null # index.html
      enable_waf          = true
      waf_monitor_mode    = true

      log_bucket = null # BUCKET_NAME.s3.REGION.amazonaws.com | null
      log_prefix = "cloudfront/"

      custom_origins = {
        alb = {
          domain_name = "myalb.us-east-1.elb.amazonaws.com"
          protocol    = "http-only"

          connection_timeout = 10
          read_timeout       = 30
          retry              = 3
        }
      }

      s3_origins = {
        s3 = {
          domain_name = "mybucket.s3.us-east-1.amazonaws.com" # BUCKET_NAME.s3.REGION.amazonaws.com
        }
      }

      default_cache_behavior = {
        origin_id       = "s3"
        allowed_methods = "GET" # GET | POST

        cache_policy_id          = "658327ea-f89d-4fab-a63d-7e88639e58f6" # CachingOptimized
        origin_request_policy_id = null
      }

      cache_behavior = {
        # Order matters
        api = {
          path_pattern    = "/v1/color"
          origin_id       = "alb"
          allowed_methods = "POST"

          cache_policy_id          = "4135ea2d-6df8-44a3-9df3-4b5a84be39ad" # CachingDisabled
          origin_request_policy_id = "216adef6-5c7f-47e4-b989-5492eafa07d3" # AllViewer
        }
      }
    }
  }
}

# {
#     "Version": "2008-10-17",
#     "Id": "PolicyForCloudFrontPrivateContent",
#     "Statement": [
#         {
#             "Sid": "AllowCloudFrontServicePrincipal",
#             "Effect": "Allow",
#             "Principal": {
#                 "Service": "cloudfront.amazonaws.com"
#             },
#             "Action": "s3:GetObject",
#             "Resource": "arn:aws:s3:::BUCKET_NAME/*",
#             "Condition": {
#                 "StringEquals": {
#                     "AWS:SourceArn": "arn:aws:cloudfront::ACCOUNT_ID:distribution/DISTRIBUTION_ID"
#                 }
#             }
#         }
#     ]
# }
