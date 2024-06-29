resource "aws_dynamodb_table" "table" {
  for_each = var.table

  name         = each.value.name
  billing_mode = "PAY_PER_REQUEST"

  hash_key  = each.value.hash_key
  range_key = try(each.value.range_key, null)

  dynamic "attribute" {
    for_each = each.value.keys

    content {
      name = attribute.value.name
      type = attribute.value.type
    }
  }

  point_in_time_recovery {
    enabled = true
  }

  server_side_encryption {
    enabled     = true
    kms_key_arn = module.kms_key[each.key].key_arn
  }

  tags = {
    "Name" = each.value.name
  }
}

module "kms_key" {
  source  = "terraform-aws-modules/kms/aws"
  version = "~> 3.0"

  for_each = var.table

  description             = "KMS key for DynamoDB table ${each.value.name}"
  deletion_window_in_days = 7
  enable_key_rotation     = true
  key_usage               = "ENCRYPT_DECRYPT"

  aliases = ["dynamodb/${each.value.name}"]
}
