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

# ── Database ──────────────────────────────────────────────────────────────────

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

# ── EC2 / ASG ────────────────────────────────────────────────────────────────

variable "ec2_instance_type" {
  description = "EC2 instance type for backend ASG and frontend"
  type        = string
  default     = "t2.micro"
}

variable "ec2_key_name" {
  description = "Name of an existing EC2 key pair for SSH access (optional, leave empty to auto-generate)"
  type        = string
  default     = ""
}

variable "asg_min_size" {
  description = "Minimum number of backend instances"
  type        = number
  default     = 2
}

variable "asg_desired_capacity" {
  description = "Desired number of backend instances"
  type        = number
  default     = 2
}

variable "asg_max_size" {
  description = "Maximum number of backend instances"
  type        = number
  default     = 4
}

variable "cpu_scale_out_threshold" {
  description = "CPU % at which ASG scales out a new backend instance"
  type        = number
  default     = 70
}

# ── Application ───────────────────────────────────────────────────────────────

variable "github_repo_url" {
  description = "GitHub repo URL (used by User Data to clone the project)"
  type        = string
  default     = "https://github.com/nadhemzini/cloud-project"
}

variable "backend_port" {
  description = "Port the Spring Boot backend listens on"
  type        = number
  default     = 8080
}

variable "health_check_path" {
  description = "ALB health check path (must return HTTP 200)"
  type        = string
  default     = "/actuator/health"
}
