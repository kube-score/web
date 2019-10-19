provider "aws" {
  region  = "eu-north-1"
  version = "2.33.0"
  profile = "gustav"
}

provider "archive" {
  version = "1.3.0"
}

provider "null" {
  version = "2.1.2"
}

provider "local" {
  version = "1.4.0"
}

terraform {
  backend "s3" {
    bucket                 = "kube-score-tf-state"
    key                    = "kube-score.tfstate"
    region                 = "eu-north-1"
    skip_region_validation = true
    profile                = "gustav"
  }
}

data "aws_region" "current" {
}
