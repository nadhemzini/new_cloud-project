# ============================================================
# Application Load Balancer
# — Spans BOTH public subnets (AZ-A + AZ-B)
# — Target Group → Backend EC2 instances on port 8080
# — Health check: GET /actuator/health → HTTP 200
# ============================================================

# ---------- ALB ----------
resource "aws_lb" "main" {
  name               = "${var.project_name}-${var.environment}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = aws_subnet.public[*].id   # both public subnets

  tags = {
    Name = "${var.project_name}-${var.environment}-alb"
  }
}

# ---------- Target Group ----------
resource "aws_lb_target_group" "backend" {
  name        = "${var.project_name}-${var.environment}-tg"
  port        = var.backend_port
  protocol    = "HTTP"
  vpc_id      = aws_vpc.main.id
  target_type = "instance"

  health_check {
    enabled             = true
    path                = var.health_check_path
    port                = "traffic-port"
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 30
    timeout             = 10
    healthy_threshold   = 2
    unhealthy_threshold = 3
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-backend-tg"
  }
}

# ---------- Listener: HTTP :80 → forward to Target Group ----------
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.backend.arn
  }
}
