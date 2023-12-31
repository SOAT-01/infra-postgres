# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 3.20.0"
    }

    postgresql = {
      source  = "cyrilgdn/postgresql"
      version = "1.21.0"
    }
  }

  backend "s3" {
    key            = "rds/main.tf"
    profile        = "default"
    encrypt        = true
  }
}
