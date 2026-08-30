output "proxy_public_ip" {
  description = "IP pública del servidor proxy (punto de entrada SSH)"
  value       = module.compute.proxy_public_ip
}

output "app1_private_ip" {
  description = "IP privada del servidor App1"
  value       = module.compute.app1_private_ip
}

output "back_private_ip" {
  description = "IP privada del servidor Back (RabbitMQ)"
  value       = module.compute.back_private_ip
}

output "db_private_ip" {
  description = "IP privada de la base de datos"
  value       = module.compute.db_private_ip
}

output "front_private_ip" {
  description = "IP privada del servidor Front"
  value       = module.compute.front_private_ip
}

output "vpc_id" {
  description = "ID de la VPC creada"
  value       = module.networking.vpc_id
}

output "vpc_cidr" {
  description = "CIDR de la VPC"
  value       = module.networking.vpc_cidr
}

output "sg_proxy_id" {
  description = "ID del security group del proxy"
  value       = module.security_groups.sg_proxy_id
}

output "sg_app1_id" {
  description = "ID del security group del servidor App1"
  value       = module.security_groups.sg_app1_id
}

output "sg_front_id" {
  description = "ID del security group del servidor Front"
  value       = module.security_groups.sg_front_id
}

output "sg_back_id" {
  description = "ID del security group del servidor Back"
  value       = module.security_groups.sg_back_id
}

output "sg_db_id" {
  description = "ID del security group de la base de datos"
  value       = module.security_groups.sg_db_id
}
