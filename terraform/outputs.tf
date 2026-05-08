# ============================================================
# Outputs
# Print after: terraform apply -var-file="sandbox.tfvars"
# ============================================================

# ── Frontend ─────────────────────────────────────────────────
output "frontend_public_ip" {
  description = "Open this URL in your browser to access the frontend"
  value       = "http://${aws_instance.frontend.public_ip}"
}

output "frontend_instance_ip" {
  description = "Raw frontend EC2 public IP (for SSH / CI-CD)"
  value       = aws_instance.frontend.public_ip
}

# ── ALB (Backend entry point) ─────────────────────────────────
output "alb_dns_name" {
  description = "ALB DNS — paste this as VITE_API_URL in frontend and CORS_ORIGINS in backend"
  value       = "http://${aws_lb.main.dns_name}"
}
output "private_key_pem" {
  value     = tls_private_key.deploy_key.private_key_pem
  sensitive = true
}
output "alb_dns_raw" {
  description = "Raw ALB DNS name (without http://)"
  value       = aws_lb.main.dns_name
}

# ── RDS ──────────────────────────────────────────────────────
output "rds_endpoint" {
  description = "RDS PostgreSQL endpoint — use as DB_HOST in backend env"
  value       = aws_db_instance.postgres.address
}

output "rds_port" {
  description = "RDS port"
  value       = aws_db_instance.postgres.port
}

# ── Network ──────────────────────────────────────────────────
output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.main.id
}

output "public_subnet_ids" {
  description = "Public subnet IDs (Frontend EC2 + ALB)"
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "Private subnet IDs (Backend ASG + RDS)"
  value       = aws_subnet.private[*].id
}

# ── SSH Key (for CI/CD) ───────────────────────────────────────
output "ssh_private_key" {
  description = "Private key to SSH into Frontend EC2 (store as GitHub Secret EC2_SSH_KEY)"
  value       = tls_private_key.deploy_key.private_key_pem
  sensitive   = true
}
