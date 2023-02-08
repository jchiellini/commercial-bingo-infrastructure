variable "environment" {
  description = "Environment for creating resources (qa, production)"
}

variable "app" {
  description = "App name"
}

variable "zone_id" {
  description = "Hosted Zone"
}

variable "domain" {
  description = "Domain route"
}

variable "certificate" {
  description = "Domain certificate"
}

variable "whitelist_ips" {
  type    = list(string)
  default = []
}
