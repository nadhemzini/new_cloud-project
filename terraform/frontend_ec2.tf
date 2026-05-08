# ============================================================
# Frontend EC2 Instance
# — t2.micro in PUBLIC subnet (us-east-1a)
# — Has public IP (accessible directly from browser)
# — Serves React build via Nginx
# — API calls go to ALB DNS (not backend EC2 IP directly)
# — User Data: installs Docker, clones repo, builds frontend with ALB URL
# ============================================================

locals {
  frontend_user_data = <<-EOF
    #!/bin/bash
    set -e
    exec > /var/log/user-data-frontend.log 2>&1

    # ── 1. System update & packages ──────────────────────────
    yum update -y
    yum install -y git

    # ── 2. Install Docker ─────────────────────────────────────
    amazon-linux-extras install docker -y
    systemctl start docker
    systemctl enable docker
    usermod -aG docker ec2-user

    # ── 3. Clone project ─────────────────────────────────────
    mkdir -p /opt/app
    cd /opt/app
    git clone ${var.github_repo_url} new_cloud-project
    chown -R ec2-user:ec2-user /opt/app/new_cloud-project

    # ── 4. Build & run frontend with ALB DNS injected ─────────
    # VITE_API_URL points to ALB — NOT the backend EC2 IP
    cd /opt/app/new_cloud-project

    docker build \
      --build-arg VITE_API_URL=http://${aws_lb.main.dns_name} \
      -t frontend:latest ./frontend

    docker run -d \
      --name frontend \
      --restart always \
      -p 80:80 \
      frontend:latest
  EOF
}

# ---------- Frontend EC2 Instance ----------
resource "aws_instance" "frontend" {
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = var.ec2_instance_type
  subnet_id              = aws_subnet.public[0].id          # public subnet AZ-A
  vpc_security_group_ids = [aws_security_group.frontend.id]
  key_name               = aws_key_pair.deploy_key.key_name
  iam_instance_profile   = data.aws_iam_instance_profile.lab_profile.name

  user_data = base64encode(local.frontend_user_data)

  root_block_device {
    volume_size = 20
    volume_type = "gp2"
  }

  # Must wait for ALB to exist so its DNS name is known at apply time
  depends_on = [aws_lb.main]

  tags = {
    Name = "${var.project_name}-${var.environment}-frontend"
  }
}
