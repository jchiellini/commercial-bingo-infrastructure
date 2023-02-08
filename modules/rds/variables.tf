variable "environment" {
  description = "Environment for creating resources (qa, production)"
}

variable "app" {
  description = "App name"
}

variable "db_name" {
  description = "DB name"
}

variable "vpc_id" {
  description = "VPC id"
}

variable "private_subnets" {
  type = list(string)
}

variable "cidr_blocks" {
  type = list(string)
}

variable "vpc_cidr_block" {
  description = "VPC CIDR Block"
}

variable "bastion_sg" {
  description = "Bastion SG"
}

variable "lambda_sg" {
  description = "Lambda SG"
}

