variable "aws_region" {
  description = "AWS region to deploy into"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Environment name (e.g. sandbox, staging, production)"
  type        = string
  default     = "sandbox"
}

variable "project_name" {
  description = "Project name used for resource naming"
  type        = string
  default     = "cloud-stack"
}

variable "db_name" {
  description = "PostgreSQL database name"
  type        = string
  default     = "appdb"
}

variable "db_username" {
  description = "PostgreSQL master username"
  type        = string
  default     = "appuser"
}

variable "db_password" {
  description = "PostgreSQL master password (no @, /, quotes, or spaces)"
  type        = string
  sensitive   = true
}

variable "ec2_instance_type" {
  description = "EC2 instance type for the backend"
  type        = string
  default     = "t2.micro"
}

variable "ec2_key_name" {
  description = "Name of an existing EC2 key pair for SSH access (optional)"
  type        = string
  default     = ""
}
