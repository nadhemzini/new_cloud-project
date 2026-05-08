terraform {
  required_version = ">= 1.6"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
  }

  backend "local" {
    path = "terraform.tfstate"
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = "cloud-stack"
      Environment = var.environment
      ManagedBy   = "terraform"
    }
  }
}

# Data sources
data "aws_caller_identity" "current" {}

data "aws_availability_zones" "available" {
  state = "available"
}

# Look up the pre-existing LabRole (AWS Academy provides this)
data "aws_iam_role" "lab_role" {
  name = "LabRole"
}

# Look up the pre-existing LabInstanceProfile
data "aws_iam_instance_profile" "lab_profile" {
  name = "LabInstanceProfile"
}
