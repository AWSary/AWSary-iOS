terraform {
  required_version = ">= 1.3.7"
}

module "backend" {
  source       = "../modules/terraform-aws-backend"
  organisation = "awsary"
  system       = "iac"
}
