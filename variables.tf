# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

variable "region" {
  default     = "us-east-2"
  description = "AWS region"
}

variable "tf_bucket" {
  description = "Bucket for Terraform State"
  sensitive   = true
}

variable "db_password" {
  description = "RDS root user password"
  sensitive   = true
}
