output "alb" {
  value = { for k, v in var.alb : k => {
    alb_arn_suffix   = aws_lb.alb[k].arn_suffix
    alb_dns_name     = aws_lb.alb[k].dns_name
    alb_listener_arn = aws_lb_listener.alb_listener[k].arn
  } }
}

output "target_group" {
  value = { for k, v in var.target_group : k => {
    target_group_arn        = aws_lb_target_group.alb_target_group[k].arn
    target_group_arn_suffix = aws_lb_target_group.alb_target_group[k].arn_suffix
  } }
}
