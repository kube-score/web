provider "aws" {
  region = "eu-north-1"

  profile = "gustav"
}

terraform {
  backend "s3" {
    bucket                 = "kube-score-tf-state"
    key                    = "kube-score.tfstate"
    region                 = "eu-north-1"
    skip_region_validation = true
    profile                = "gustav"
  }

  required_providers {
    aws = {
      version = "4.2.0"
    }

    archive = {
      version = "2.2.0"
    }

    null = {
      version = "3.1.0"
    }

    local = {
      version = "2.1.0"
    }
  }
}

data "aws_region" "current" {
}

module "score_v2" {
  source             = "./func"
  work_dir           = "../funcs/score/v2"
  name               = "score_v2"
  aws_iam_role_arn   = aws_iam_role.kube_score_lambda.arn
  aws_region_name    = data.aws_region.current.name
  rest_api_id        = aws_api_gateway_rest_api.kube_score_api.id
  rest_api_parent_id = aws_api_gateway_rest_api.kube_score_api.root_resource_id
  root               = abspath("..")
}
