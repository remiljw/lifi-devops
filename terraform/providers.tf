terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.46"
    }
  }

  required_version = "~> 1.9.0"

  backend "s3" {
    bucket         = "lifi-terraform-state"
    key            = "dev/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "lifi-terraform-lock"
    encrypt        = true
  }
}

provider "aws" {
  default_tags {
    tags = {
      owner       = "Michael Ajanaku"
      application = var.application
    }
  }
}

