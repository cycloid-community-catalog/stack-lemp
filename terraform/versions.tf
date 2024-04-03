
terraform {
  required_version = ">= 0.13"
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
    toggles = {
      source  = "reinoudk/toggles"
      version = "0.3.0"
    }
  }
}
