terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.46"
    }
  }

  required_version = "~> 1.9.0"

  # set your own backend here if you wish
  #   backend "s3" {
  #     bucket         = ""
  #     key            = ""
  #     region         = ""
  #     dynamodb_table = ""
  #     encrypt        = true
  #   }
}

provider "aws" {
  default_tags {
    tags = {
      owner       = var.owner
      application = var.application
    }
  }
}

