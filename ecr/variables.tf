variable "repositories" {
  type        = map(any)
  description = "Map for ECR repositories"

  default = {
    myapp = {}
  }
}
