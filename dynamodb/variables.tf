variable "table" {
  type        = any
  description = "Map for DynamoDB table"

  default = {
    table1 = {
      name = "product"

      hash_key  = "id"
      range_key = null

      keys = [
        {
          name = "id"
          type = "S"
        },
        # {
        #   name = "category"
        #   type = "S"
        # },
      ]
    }
  }
}
