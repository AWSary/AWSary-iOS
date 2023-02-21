provider "aws" {
  region  = local.region
  profile = "tig-awsary"
  default_tags {
    tags = {
      terraform     = "true"
      region        = local.region
      business-unit = "awsary"
      stage         = terraform.workspace
      repository    = "https://github.com/tigpt/AWSary"
    }
  }
}