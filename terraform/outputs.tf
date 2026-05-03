output "app_public_ip" {
  description = "EC2 public IP (App Server)"
  value       = aws_instance.app.public_ip
}

output "frontend_url" {
  description = "Frontend URL"
  value       = "http://${aws_instance.app.public_ip}"
}

output "backend_url" {
  description = "Backend API URL"
  value       = "http://${aws_instance.app.public_ip}:8080"
}

output "rds_endpoint" {
  description = "RDS PostgreSQL endpoint"
  value       = aws_db_instance.postgres.endpoint
}

output "deploy_private_key" {
  description = "SSH Private Key for GitHub Actions Deployment (EC2_SSH_KEY secret)"
  value       = tls_private_key.deploy_key.private_key_pem
  sensitive   = true
}
