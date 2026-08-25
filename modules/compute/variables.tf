variable "ami" {
  description = "AMI para todas las instancias EC2"
  type        = string
}

variable "subnet_publica_id" {
  description = "ID de la subnet pública (para el proxy)"
  type        = string
}

variable "subnet_privada_id" {
  description = "ID de la subnet privada (para todos los demás)"
  type        = string
}

variable "sg_proxy_id" {
  description = "ID del security group del proxy"
  type        = string
}

variable "sg_ia_id" {
  description = "ID del security group de Airflow (IA)"
  type        = string
}

variable "sg_front_id" {
  description = "ID del security group de workers de Airflow (front)"
  type        = string
}

variable "sg_back_id" {
  description = "ID del security group de RabbitMQ (back)"
  type        = string
}

variable "sg_db_id" {
  description = "ID del security group de DB"
  type        = string
}

variable "key_proxy" {
  description = "Ruta local al archivo de clave pública para el servidor proxy"
  type        = string
  sensitive   = true
}

variable "key_general" {
  description = "Ruta local al archivo de clave pública para los servidores privados"
  type        = string
  sensitive   = true
}

variable "environment" {
  description = "Ambiente de despliegue"
  type        = string
  default     = "dev"
}

variable "owner" {
  description = "Responsable del proyecto"
  type        = string
  default     = "estudiante"
}
