output "db_name" {
  value = module.db_rds.db_instance_name
}

output "db_username" {
  value = module.db_rds.db_instance_username
}

output "db_password" {
  value = module.db_rds.db_instance_password
}

output "db_port" {
  value = module.db_rds.db_instance_port
}

output "db_proxy_endpoint" {
  value = aws_db_proxy.rds_proxy.endpoint
}
