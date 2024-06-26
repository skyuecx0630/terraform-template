variable "efs" {
  type        = map(any)
  description = "Map for EFS"

  default = {
    skills-efs = {
      throughput_mode = "elastic" # bursting | provisioned | elastic

      # provisioned_throughput_in_mibps = 5

      subnet_ids         = ["subnet-0ee77ccc2b8e89123", "subnet-0f2a26a83b3cc6a20"]
      security_group_ids = ["sg-02a05857a76455e9a"]

      access_point_path = "/skills"
      access_point_uid  = 10001
      access_point_gid  = 10001
    }
  }
}
