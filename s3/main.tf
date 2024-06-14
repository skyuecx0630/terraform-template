provider "aws" {
  default_tags {
    tags = {
      "project" = "skills"
      "owner"   = "hmoon"
    }
  }
}

module "kms_key" {
  source  = "terraform-aws-modules/kms/aws"
  version = "~> 3.0"

  for_each = { for k, v in var.buckets : k => v if v.enable_kms_encryption }

  aliases             = ["alias/s3/${each.value.name}"]
  enable_key_rotation = true
  description         = "KMS key for encrypting S3 bucket objects"
}

module "s3_bucket" {
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "~> 4.1"

  for_each = var.buckets

  bucket        = each.value.name
  force_destroy = true

  attach_deny_insecure_transport_policy = each.value.policy_https
  attach_elb_log_delivery_policy        = each.value.policy_elb_log

  server_side_encryption_configuration = {
    rule = {
      apply_server_side_encryption_by_default = each.value.enable_kms_encryption ? {
        kms_master_key_id = module.kms_key[each.key].key_id
        sse_algorithm     = "aws:kms"
        } : {
        sse_algorithm = "AES256"
      }
      bucket_key_enabled = true
    }
  }

  versioning = {
    enabled = true
  }

  lifecycle_rule = [
    {
      id      = "log"
      enabled = true

      transition = [
        {
          days          = 30
          storage_class = "STANDARD_IA"
        },
        {
          days          = 60
          storage_class = "ONEZONE_IA"
        }
      ]
    }
  ]

  intelligent_tiering = {
    general = {
      status = "Enabled"
      tiering = {
        ARCHIVE_ACCESS = {
          days = 90
        }
        DEEP_ARCHIVE_ACCESS = {
          days = 180
        }
      }
    }
  }
}
