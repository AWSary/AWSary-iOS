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

provider "aws" {
  profile = "tig-awsary"
  alias   = "us-east-1"
  region  = "us-east-1"
  default_tags {
    tags = {
      terraform     = "true"
      region        = "us-east-1"
      business-unit = "awsary"
      stage         = terraform.workspace
      repository    = "https://github.com/tigpt/AWSary"
    }
  }
}