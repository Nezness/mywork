#-------------------------
# Terraform configuration
#-------------------------
terraform {
  required_version = ">=1.14"
  required_providers {
    aws = {
      version = "~>6.0"
    }
  }
}

// provider is on profile.tf(hidden)

#-------------------------
# Variables
#-------------------------
variable "project" {
  type = string
}

variable "environment" {
  type = string
}

variable "domain" {
  type = string
}

