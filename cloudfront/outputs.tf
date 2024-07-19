output "distribution" {
  value = {
    for k, v in var.distribution :
    k => {
      domain_name = aws_cloudfront_distribution.distribution[k].domain_name
    }
  }
}
