module "dynamodb_table" {
  source = "terraform-aws-modules/dynamodb-table/aws"

  name      = "AWSary-services"
  hash_key  = "id"
  range_key = "name"

  billing_mode = "PAY_PER_REQUEST"

  attributes = [
    {
      name = "id"
      type = "N"
    },
    {
      name = "name"
      type = "S"
    }
  ]
}