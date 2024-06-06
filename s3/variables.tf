variable "buckets" {
  type        = map(any)
  description = "Map for S3 buckets"

  default = {
    mylogbucket = {
      name                  = "mylogbucket"
      policy_https          = true
      policy_elb_log        = true
      enable_kms_encryption = false
    }
    mykmsbucket = {
      name                  = "mykmsbucket"
      policy_https          = true
      policy_elb_log        = false
      enable_kms_encryption = true
    }
  }
}
