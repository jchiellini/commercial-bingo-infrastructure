variable "org" {
  description = "Organization"
}

variable "cidr_block" {
  description = "CIDR Block"
}

variable "app" {
  description = "App name"
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
