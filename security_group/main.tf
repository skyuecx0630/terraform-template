data "aws_ec2_managed_prefix_list" "cloudfront" {
  name = "com.amazonaws.global.cloudfront.origin-facing"
}

resource "aws_security_group" "security_group" {
  for_each = var.security_group

  name        = each.key
  description = each.key

  vpc_id = var.vpc_id

  dynamic "egress" {
    for_each = try(each.value.enable_egress, true) ? [1] : []
    content {
      from_port = 0
      to_port   = 0
      protocol  = "-1"

      cidr_blocks = ["0.0.0.0/0"]
    }
  }

  tags = {
    Name = each.key
  }
}

resource "aws_security_group" "preset_security_group" {
  for_each = var.preset

  name        = each.value.name
  description = each.value.name

  vpc_id = var.vpc_id

  tags = {
    Name = each.value.name
  }
}

resource "aws_security_group_rule" "alb_ingress_rule" {
  count = try(var.preset.alb.name, null) != null ? 1 : 0

  security_group_id = aws_security_group.preset_security_group["alb"].id
  type              = "ingress"

  from_port = var.preset.alb.port
  to_port   = var.preset.alb.port
  protocol  = "tcp"

  cidr_blocks     = var.preset.alb.cloudfront_only ? null : ["0.0.0.0/0"]
  prefix_list_ids = var.preset.alb.cloudfront_only ? [data.aws_ec2_managed_prefix_list.cloudfront.id] : null
}

resource "aws_security_group_rule" "alb_egress_rule" {
  count = try(var.preset.alb.name, null) != null ? 1 : 0

  security_group_id = aws_security_group.preset_security_group["alb"].id
  type              = "egress"

  from_port = 0
  to_port   = 0
  protocol  = "-1"

  cidr_blocks = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "app_ingress_rule" {
  count = try(var.preset.app.name, null) != null ? 1 : 0

  security_group_id = aws_security_group.preset_security_group["app"].id
  type              = "ingress"

  from_port = var.preset.app.port
  to_port   = var.preset.app.port
  protocol  = "tcp"

  source_security_group_id = aws_security_group.preset_security_group["alb"].id
}

resource "aws_security_group_rule" "app_egress_rule" {
  count = try(var.preset.app.name, null) != null ? 1 : 0

  security_group_id = aws_security_group.preset_security_group["app"].id
  type              = "egress"

  from_port = 0
  to_port   = 0
  protocol  = "-1"

  cidr_blocks = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "rds_ingress_rule" {
  count = try(var.preset.rds.name, null) != null ? 1 : 0

  security_group_id = aws_security_group.preset_security_group["rds"].id
  type              = "ingress"

  from_port = var.preset.rds.port
  to_port   = var.preset.rds.port
  protocol  = "tcp"

  source_security_group_id = aws_security_group.preset_security_group["app"].id
}
