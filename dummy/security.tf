# ==================================================
# Inspector
# ==================================================

resource "aws_inspector2_enabler" "inspector" {
  count = var.dummy.inspector ? 1 : 0

  account_ids    = [data.aws_caller_identity.current.account_id]
  resource_types = ["EC2", "ECR", "LAMBDA", "LAMBDA_CODE"]
}

# ==================================================
# GuardDuty
# ==================================================

resource "aws_guardduty_detector" "guardduty" {
  count = var.dummy.guardduty ? 1 : 0

  enable = true

  finding_publishing_frequency = "FIFTEEN_MINUTES"
  datasources {
    s3_logs {
      enable = true
    }
    kubernetes {
      audit_logs {
        enable = true
      }
    }
    malware_protection {
      scan_ec2_instance_with_findings {
        ebs_volumes {
          enable = true
        }
      }
    }
  }
}

resource "aws_guardduty_detector_feature" "guardduty_feature1" {
  count = var.dummy.guardduty ? 1 : 0

  detector_id = aws_guardduty_detector.guardduty[0].id
  name        = "RUNTIME_MONITORING"
  status      = "ENABLED"

  additional_configuration {
    name   = "EKS_ADDON_MANAGEMENT"
    status = "ENABLED"
  }
  additional_configuration {
    name   = "ECS_FARGATE_AGENT_MANAGEMENT"
    status = "ENABLED"
  }
  additional_configuration {
    name   = "EC2_AGENT_MANAGEMENT"
    status = "ENABLED"
  }
}

resource "aws_guardduty_detector_feature" "guardduty_feature2" {
  count = var.dummy.guardduty ? 1 : 0

  detector_id = aws_guardduty_detector.guardduty[0].id
  name        = "LAMBDA_NETWORK_LOGS"
  status      = "ENABLED"
}

# ==================================================
# Macie
# ==================================================

resource "aws_macie2_account" "macie" {
  count = var.dummy.macie ? 1 : 0

  finding_publishing_frequency = "FIFTEEN_MINUTES"
  status                       = "ENABLED"
}

# ==================================================
# Config
# ==================================================

data "aws_iam_policy_document" "config_assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["config.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

data "aws_iam_policy_document" "config_policy" {
  statement {
    effect  = "Allow"
    actions = ["s3:*"]
    resources = [
      aws_s3_bucket.config_bucket[0].arn,
      "${aws_s3_bucket.config_bucket[0].arn}/*"
    ]
  }
}

resource "aws_iam_role" "config_role" {
  count = var.dummy.config ? 1 : 0

  name               = "dummy-config-role"
  assume_role_policy = data.aws_iam_policy_document.config_assume_role.json
}

resource "aws_iam_role_policy" "p" {
  count = var.dummy.config ? 1 : 0

  name   = "dummy-config-role-policy"
  role   = aws_iam_role.config_role[0].id
  policy = data.aws_iam_policy_document.config_policy.json
}

resource "aws_s3_bucket" "config_bucket" {
  count = var.dummy.config ? 1 : 0

  bucket        = "dummy-config-${data.aws_caller_identity.current.account_id}-${data.aws_region.current.name}"
  force_destroy = true
}

resource "aws_config_delivery_channel" "config_delivery_channel" {
  count = var.dummy.config ? 1 : 0

  name           = "dummy-recorder"
  s3_bucket_name = aws_s3_bucket.config_bucket[0].id
  depends_on     = [aws_config_configuration_recorder.config[0]]
}

resource "aws_config_configuration_recorder_status" "config_status" {
  count = var.dummy.config ? 1 : 0

  name       = "dummy-recorder"
  is_enabled = true
  depends_on = [aws_config_delivery_channel.config_delivery_channel[0]]
}

resource "aws_config_configuration_recorder" "config" {
  count = var.dummy.config ? 1 : 0

  name     = "dummy-recorder"
  role_arn = aws_iam_role.config_role[0].arn
}
