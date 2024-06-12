variable "repositories" {
  type        = map(any)
  description = "Map for ECR repositories"

  default = {
    myapp = {}
    # test = {
    #   encrypted    = false
    #   immutable    = false
    #   scan_on_push = false
    # }
  }
}
