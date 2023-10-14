# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "4.52.0"
    }
  }

  backend "s3" {
    bucket = var.tf_bucket
    key    = "tfstate/rds.tf"
    region = var.region
    profile = "default"
    encrypt = true
    dynamodb_table = "terraform-state-lock"
  }
}

provider "aws" {
  region = var.region
}

data "aws_availability_zones" "available" {}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "2.77.0"

  name                 = "fast_food"
  cidr                 = "10.0.0.0/16"
  azs                  = data.aws_availability_zones.available.names
  public_subnets       = ["10.0.4.0/24", "10.0.5.0/24", "10.0.6.0/24"]
  enable_dns_hostnames = true
  enable_dns_support   = true
}

resource "aws_db_subnet_group" "fast_food" {
  name       = "fast_food"
  subnet_ids = module.vpc.public_subnets

  tags = {
    Name = "fast_food"
  }
}

resource "aws_security_group" "rds" {
  name   = "fast_food_rds"
  vpc_id = module.vpc.vpc_id

  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "fast_food_rds"
  }
}

resource "aws_db_parameter_group" "fast_food" {
  name   = "fast-food-parameter-group"
  family = "postgres15"

  parameter {
    name  = "log_connections"
    value = "1"
  }
}

resource "aws_db_instance" "fast_food" {
  identifier             = "fast-food-db"
  instance_class         = "db.t3.micro"
  allocated_storage      = 5
  engine                 = "postgres"
  engine_version         = "15.3"
  username               = "db_master_ff"
  password               = var.db_password
  db_subnet_group_name   = aws_db_subnet_group.fast_food.name
  vpc_security_group_ids = [aws_security_group.rds.id]
  parameter_group_name   = aws_db_parameter_group.fast_food.name
  publicly_accessible    = true
  skip_final_snapshot    = true
}
