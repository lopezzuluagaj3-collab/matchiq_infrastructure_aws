# versions.tf
terraform {
  required_version = ">= 1.7.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.4"
    }
  }

  backend "s3" {
    bucket  = "sirius-terraform-state-022784797877"
    key     = "cruster/terraform.tfstate"
    region  = "us-east-1"
    encrypt = true
  }
}