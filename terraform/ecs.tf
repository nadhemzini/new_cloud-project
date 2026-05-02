# ============================================================
# EC2 — Backend Server (replaces ECS Fargate for AWS Academy)
# ============================================================

# ---------- Security Group: EC2 Backend ----------
resource "aws_security_group" "backend" {
  name        = "${var.project_name}-${var.environment}-backend-sg"
  description = "Allow HTTP 8080 and SSH"
  vpc_id      = aws_vpc.main.id

  # HTTP access to Spring Boot
  ingress {
    description = "Backend API"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # SSH access (optional, for debugging)
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
    Name = "${var.project_name}-${var.environment}-backend-sg"
  }
}

# ---------- EC2 User Data (startup script) ----------
locals {
  user_data = <<-EOF
    #!/bin/bash
    set -e

    # Update system
    yum update -y

    # Install Docker
    amazon-linux-extras install docker -y || yum install docker -y
    systemctl start docker
    systemctl enable docker

    # Install Docker Compose
    curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    chmod +x /usr/local/bin/docker-compose

    # Install Java 17
    yum install java-17-amazon-corretto-headless -y

    # Install Maven
    yum install maven -y || {
      curl -L https://dlcdn.apache.org/maven/maven-3/3.9.6/binaries/apache-maven-3.9.6-bin.tar.gz -o /tmp/maven.tar.gz
      tar xzf /tmp/maven.tar.gz -C /opt
      ln -s /opt/apache-maven-3.9.6/bin/mvn /usr/local/bin/mvn
    }

    # Install Git
    yum install git -y

    # Create app directory
    mkdir -p /opt/app
    cd /opt/app

    # Create the Spring Boot application.yml with env vars
    mkdir -p backend/src/main/resources
    cat > backend/src/main/resources/application.yml << 'APPYML'
    spring:
      datasource:
        url: jdbc:postgresql://${aws_db_instance.postgres.address}:5432/${var.db_name}
        username: ${var.db_username}
        password: ${var.db_password}
      jpa:
        hibernate:
          ddl-auto: update
        show-sql: false
        properties:
          hibernate:
            dialect: org.hibernate.dialect.PostgreSQLDialect

    server:
      port: 8080

    management:
      endpoints:
        web:
          exposure:
            include: health

    app:
      cors:
        allowed-origins: "*"
    APPYML

    echo "EC2 backend setup complete" > /opt/app/setup.log
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

  filter {
    name   = "state"
    values = ["available"]
  }
}

# ---------- EC2 Instance ----------
resource "aws_instance" "backend" {
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = var.ec2_instance_type
  subnet_id              = aws_subnet.public[0].id
  vpc_security_group_ids = [aws_security_group.backend.id]
  iam_instance_profile   = data.aws_iam_instance_profile.lab_profile.name

  key_name = var.ec2_key_name != "" ? var.ec2_key_name : null

  user_data = base64encode(local.user_data)

  root_block_device {
    volume_size = 20
    volume_type = "gp2"
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-backend"
  }
}
