provider "aws" {
  region  = "eu-north-1"
  version = "2.6.0"
  profile = "gustav"
}

provider "archive" {
  version = "1.2.1"
}

terraform {
  backend "s3" {
    bucket = "kube-score-tf-state"
    key    = "kube-score.tfstate"
    region = "eu-north-1"
    skip_region_validation = true
    profile = "gustav"
  }
}


data "aws_region" "current" {}

data "archive_file" "kube_score_go" {
  type        = "zip"
  source_file = "${path.module}/../api-linux-amd64"
  output_path = "${path.module}/files/kube_score_api.zip"
}
