# ============================================================
# Launch Template for Backend Auto Scaling Group
# — Amazon Linux 2 AMI (latest)
# — Installs Docker, clones repo, starts Spring Boot via Docker
# — All env vars injected at boot (DB_HOST from RDS, etc.)
# ============================================================

# ---------- Auto-generate deploy key for SSH ----------
resource "tls_private_key" "deploy_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "deploy_key" {
  key_name   = "${var.project_name}-${var.environment}-deploy-key"
  public_key = tls_private_key.deploy_key.public_key_openssh
}

# ---------- Latest Amazon Linux 2 AMI ----------
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

# ---------- Backend User Data ----------
locals {
  backend_user_data = <<-EOF
    #!/bin/bash
    set -e
    exec > /var/log/user-data.log 2>&1

    # ── 1. System update & packages ──────────────────────────
    yum update -y
    yum install -y git

    # ── 2. Install Docker ─────────────────────────────────────
    amazon-linux-extras install docker -y
    systemctl start docker
    systemctl enable docker
    usermod -aG docker ec2-user

    # ── 3. Install Docker Compose V2 ─────────────────────────
    mkdir -p /usr/local/lib/docker/cli-plugins/
    curl -SL https://github.com/docker/compose/releases/latest/download/docker-compose-linux-x86_64 \
      -o /usr/local/lib/docker/cli-plugins/docker-compose
    chmod +x /usr/local/lib/docker/cli-plugins/docker-compose
    ln -sf /usr/local/lib/docker/cli-plugins/docker-compose /usr/bin/docker-compose

    # ── 4. Clone project ─────────────────────────────────────
    mkdir -p /opt/app
    cd /opt/app
    git clone ${var.github_repo_url} cloud-project
    chown -R ec2-user:ec2-user /opt/app/cloud-project

    # ── 5. Write environment file ─────────────────────────────
    # DB_HOST injected by Terraform interpolation at apply time
    cat > /opt/app/cloud-project/.env <<ENV
    DB_URL=jdbc:postgresql://${aws_db_instance.postgres.address}:5432/${var.db_name}
    DB_USERNAME=${var.db_username}
    DB_PASSWORD=${var.db_password}
    CORS_ORIGINS=http://${aws_lb.main.dns_name}
    SERVER_PORT=${var.backend_port}
    ENV

    chown ec2-user:ec2-user /opt/app/cloud-project/.env

    # ── 6. Start backend only (no frontend on this EC2) ──────
    cd /opt/app/cloud-project
    docker-compose -f docker-compose.prod.yml up -d backend
  EOF
}

# ---------- Launch Template ----------
resource "aws_launch_template" "backend" {
  name_prefix   = "${var.project_name}-${var.environment}-backend-lt-"
  image_id      = data.aws_ami.amazon_linux.id
  instance_type = var.ec2_instance_type
  key_name      = aws_key_pair.deploy_key.key_name

  network_interfaces {
    associate_public_ip_address = false   # private subnet — no public IP
    security_groups             = [aws_security_group.backend.id]
  }

  iam_instance_profile {
    name = data.aws_iam_instance_profile.lab_profile.name
  }

  user_data = base64encode(local.backend_user_data)

  block_device_mappings {
    device_name = "/dev/xvda"
    ebs {
      volume_size = 20
      volume_type = "gp2"
    }
  }

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "${var.project_name}-${var.environment}-backend"
    }
  }

  lifecycle {
    create_before_destroy = true
  }
}
