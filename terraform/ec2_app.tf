# ============================================================
# EC2 — Unified Application Server (Frontend & Backend)
# ============================================================

# ---------- Security Group: EC2 App ----------
resource "aws_security_group" "app" {
  name        = "${var.project_name}-${var.environment}-app-sg"
  description = "Allow HTTP 80, 8080, and SSH"
  vpc_id      = aws_vpc.main.id

  # Frontend HTTP access
  ingress {
    description = "Frontend"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Backend API access
  ingress {
    description = "Backend API"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # SSH access (for GitHub Actions CI/CD)
  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-app-sg"
  }
}

# ---------- SSH Key Generation for CI/CD ----------
# Generates a new RSA private key
resource "tls_private_key" "deploy_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# Registers the public key with AWS EC2
resource "aws_key_pair" "deploy_key" {
  key_name   = "${var.project_name}-${var.environment}-deploy-key"
  public_key = tls_private_key.deploy_key.public_key_openssh
}

# ---------- EC2 User Data (startup script) ----------
locals {
  app_user_data = <<-EOF
    #!/bin/bash
    set -e

    yum update -y
    
    # Install Docker
    amazon-linux-extras install docker -y || yum install docker -y
    systemctl start docker
    systemctl enable docker
    usermod -a -G docker ec2-user

    # Install Docker Compose (V2)
    mkdir -p /usr/local/lib/docker/cli-plugins/
    curl -SL https://github.com/docker/compose/releases/latest/download/docker-compose-linux-x86_64 -o /usr/local/lib/docker/cli-plugins/docker-compose
    chmod +x /usr/local/lib/docker/cli-plugins/docker-compose
    ln -s /usr/local/lib/docker/cli-plugins/docker-compose /usr/bin/docker-compose

    yum install git -y

    mkdir -p /opt/app
    cd /opt/app

    # Clone the repository
    git clone https://github.com/nadhemzini/cloud-project
    cd cloud-project
    
    # Allow ec2-user to modify the app directory (for GitHub Actions)
    chown -R ec2-user:ec2-user /opt/app/cloud-project

    # Fetch public IP dynamically using IMDSv2
    TOKEN=$(curl -s -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")
    PUBLIC_IP=$(curl -s -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/public-ipv4)

    # Create .env file for Docker Compose
    cat > .env << ENV_EOF
    DB_URL=jdbc:postgresql://${aws_db_instance.postgres.address}:5432/${var.db_name}
    DB_USERNAME=${var.db_username}
    DB_PASSWORD=${var.db_password}
    VITE_API_URL=http://$PUBLIC_IP:8080
    ENV_EOF

    # Fix ownership of .env
    chown ec2-user:ec2-user .env

    # Initial start using docker-compose.prod.yml
    docker-compose -f docker-compose.prod.yml up -d --build
  EOF
}

# ---------- Find latest Amazon Linux 2 AMI ----------
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

# ---------- EC2 Instance: App Server ----------
resource "aws_instance" "app" {
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = var.ec2_instance_type
  subnet_id              = aws_subnet.public[0].id
  vpc_security_group_ids = [aws_security_group.app.id]
  iam_instance_profile   = data.aws_iam_instance_profile.lab_profile.name

  # Attach the dynamically generated key pair
  key_name = aws_key_pair.deploy_key.key_name

  user_data = base64encode(local.app_user_data)

  root_block_device {
    volume_size = 20
    volume_type = "gp2"
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-app"
  }
}
