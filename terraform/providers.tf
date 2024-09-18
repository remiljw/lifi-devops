terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.46"
    }
  }

  required_version = "~> 1.9.0"

  backend "s3" {}
}

provider "aws" {
  default_tags {
    tags = {
        owner = "Michael Ajanaku"
        application = var.application
    }
  }
}

