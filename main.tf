# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

provider "aws" {
  region = var.region
}

data "aws_availability_zones" "available" {}

module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

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

  parameter {
    name  = "rds.force_ssl"
    value = "0"
  }
}

resource "aws_db_instance" "fast_food" {
  identifier             = "fast-food-db"
  instance_class         = "db.t3.micro"
  allocated_storage      = 5
  engine                 = "postgres"
  engine_version         = "15.3"
  username               = var.db_user
  password               = var.db_password
  db_subnet_group_name   = aws_db_subnet_group.fast_food.name
  vpc_security_group_ids = [aws_security_group.rds.id]
  parameter_group_name   = aws_db_parameter_group.fast_food.name
  publicly_accessible    = true
  skip_final_snapshot    = true
  apply_immediately      = true
  depends_on = [aws_security_group.rds, aws_db_parameter_group.fast_food, aws_db_subnet_group.fast_food]
}

resource "aws_ssm_parameter" "db_hostname" {
  name        = "/db/db_hostname"
  type        = "SecureString"
  description = "DB Hostname"
  value       = aws_db_instance.fast_food.address
  depends_on = [aws_db_instance.fast_food ]
}

provider "postgresql" {
  scheme   = "postgres"
  host     = aws_ssm_parameter.db_hostname.value
  port     = var.db_port
  username = var.db_user
  password = var.db_password
  superuser = false
}

resource "postgresql_database" "cliente" {
  name              = "cliente"
  owner             = var.db_user
  connection_limit  = -1
  allow_connections = true
  depends_on = [aws_db_instance.fast_food ]
}

resource "postgresql_role" "cliente_role" {
  name = "cliente_role"
  depends_on = [postgresql_database.cliente ]
}

resource "postgresql_role" "cliente_user" {                                                                                                                                                 
  name     = var.cliente_user                                                                                                                                                                 
  password = var.cliente_password                                                                                                                                                          
  login    = true                                                                                                                                                                            
  roles = [postgresql_role.cliente_role.name]         
  depends_on = [postgresql_database.cliente ]                                                                                                                                      
}

resource "postgresql_grant" "grant_cliente" {
  database    = postgresql_database.cliente.name
  role        = postgresql_role.cliente_role.name
  object_type = "database"
  privileges  = ["ALL"]
  depends_on = [postgresql_database.cliente ]
}

resource "postgresql_grant" "grant_public_cliente" {
  database    = postgresql_database.cliente.name
  role        = postgresql_role.cliente_role.name
  schema      = "public"
  object_type = "schema"
  privileges  = ["ALL"]
  depends_on = [postgresql_database.cliente ]
}

resource "postgresql_database" "produto" {
  name              = "produto"
  owner             = var.db_user
  connection_limit  = -1
  allow_connections = true
  depends_on = [aws_db_instance.fast_food ]
}

resource "postgresql_role" "produto_role" {
  name = "produto_role"
  depends_on = [postgresql_database.produto ]
}

resource "postgresql_role" "produto_user" {                                                                                                                                                 
  name     = var.produto_user                                                                                                                                                                
  password = var.produto_password                                                                                                                                                          
  login    = true                                                                                                                                                                            
  roles = [postgresql_role.produto_role.name]     
  depends_on = [postgresql_database.produto ]                                                                                                                                          
}

resource "postgresql_grant" "grant_produto" {
  database    = postgresql_database.produto.name
  role        = postgresql_role.produto_role.name
  object_type = "database"
  privileges  = ["ALL"]
  depends_on = [postgresql_database.produto ]
}

resource "postgresql_grant" "grant_public_produto" {
  database    = postgresql_database.produto.name
  role        = postgresql_role.produto_role.name
  schema      = "public"
  object_type = "schema"
  privileges  = ["ALL"]
  depends_on = [postgresql_database.produto ]
}