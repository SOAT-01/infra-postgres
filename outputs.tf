# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

output "vpc_id" {
  description = "VPC Id"
  value       = try(module.vpc.aws_vpc.this[0].id, null)
  sensitive   = false
}

output "rds_hostname" {
  description = "RDS instance hostname"
  value       = aws_db_instance.fast_food.address
  sensitive   = false
}

output "rds_port" {
  description = "RDS instance port"
  value       = aws_db_instance.fast_food.port
  sensitive   = false
}

output "rds_username" {
  description = "RDS instance root username"
  value       = aws_db_instance.fast_food.username
  sensitive   = true
}