resource "aws_ecr_repository" "repository" {
  for_each = var.repositories

  name         = each.key
  force_delete = true

  dynamic "encryption_configuration" {
    for_each = try(each.value.encrypted, true) ? [1] : []
    content {
      encryption_type = "KMS"
      kms_key         = module.kms_key[each.key].key_arn
    }
  }

  image_scanning_configuration {
    scan_on_push = try(each.value.scan_on_push, true)
  }

  image_tag_mutability = try(each.value.immutable, true) ? "IMMUTABLE" : "MUTABLE"
}

module "kms_key" {
  source  = "terraform-aws-modules/kms/aws"
  version = "~> 3.0"

  for_each = var.repositories

  create = try(each.value.encrypted, true)

  description             = "KMS key for encrypting ECR image ${each.key}"
  deletion_window_in_days = 7
  enable_key_rotation     = true
  key_usage               = "ENCRYPT_DECRYPT"

  aliases = ["ecr/${each.key}"]
}
