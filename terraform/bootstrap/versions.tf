terraform {
  required_version = "~> 1"
  required_providers {
    aws = {
      version = "~> 5"
    }
    awscc = {
      source  = "hashicorp/awscc"
      version = "~> 1.4.0"
    }
  }
}
