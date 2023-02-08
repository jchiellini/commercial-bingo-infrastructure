variable "environment" {
  description = "Environment for creating resources (qa, production)"
}

variable "domain" {
  description = "Domain route"
}

variable "certificate" {
  description = "Domain certificate"
}

variable "zone_id" {
  description = "Hosted Zone"
}

variable "app" {
  description = "App name"
}

variable "lambda_sg" {
  description = "Lambda SG"
}

variable "private_subnets" {
  description = "Private subnets"
  type        = list(string)
}

variable "db_proxy_endpoint" {
  description = "DB Proxy endpoint"
}

variable "db_username" {
  description = "DB Username"
}

variable "db_password" {
  description = "DB Password"
}

variable "db_port" {
  description = "DB Port"
}

variable "db_name" {
  description = "DB Name"
}

variable "whitelist_ips" {
  type    = list(string)
  default = []
}

