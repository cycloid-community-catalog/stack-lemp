provider "aws" {
  access_key = var.access_key
  secret_key = var.secret_key
  region     = var.aws_region
  default_tags {
    tags = {
      "cycloid.io" = "true"
      env          = var.env
      project      = var.project
      organization = var.organization
      component    = var.component
      client       = var.organization # Used by legacy stop-start feature. This will be replaced by organization tag
    }
  }
}


variable "organization" {
}

variable "project" {
}

variable "env" {
}

variable "component" {
}

variable "rds_password" {
  default = "ChangeMePls"
}

variable "deploy_bucket_name" {
}

variable "access_key" {
}

variable "secret_key" {
}

variable "aws_region" {
  description = "AWS region to launch servers."
  default     = "eu-west-1"
}
