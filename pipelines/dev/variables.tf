variable "region" {
  description = "Region that the instances will be created"
}

variable "environment" {
  description = "Environment for creating resources (qa, production)"
}

variable "org" {
  description = "Organization"
  default     = "commercial-bingo"
}

variable "app" {
  description = "App name"
  default     = "commercial-bingo-app"
}

variable "cidr_block" {
  description = "CIDR Block"
}

variable "db_name" {
  description = "DB name"
}

variable "terraform_backend_name" {
  description = "Terraform Backend Name"
}

variable "domain" {
  description = "Domain name"
}

variable "frontend_domain" {
  description = "Domain name"
}

variable "backend_domain" {
  description = "Domain name"
}

variable "whitelist_ips" {
  type    = list(string)
  default = []
}

variable "vpc_id" {
  description = "VPC id"
}

variable "igw_id" {
  description = "Internet Gateway Id"
}

variable "private_subnet_range" {
  description = "Private Subnet Range"
}

variable "public_subnet_range" {
  description = "Public Subnet Range"
}
