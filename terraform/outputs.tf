output "backend_public_ip" {
  description = "EC2 public IP (backend API)"
  value       = aws_instance.backend.public_ip
}

output "backend_url" {
  description = "Backend API URL"
  value       = "http://${aws_instance.backend.public_ip}:8080"
}

output "rds_endpoint" {
  description = "RDS PostgreSQL endpoint"
  value       = aws_db_instance.postgres.endpoint
  sensitive   = true
}
