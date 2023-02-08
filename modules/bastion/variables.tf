variable "environment" {
  description = "Environment for creating resources (qa, production)"
}

variable "app" {
  description = "App name"
}

variable "vpc_id" {
  description = "VPC Id"
}

variable "subnets" {
  description = "Private Subnets"
  type        = list(string)
}
