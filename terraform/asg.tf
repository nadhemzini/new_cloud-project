# ============================================================
# Auto Scaling Group
# — min=2, desired=2, max=4 across BOTH private subnets
# — Attached to ALB Target Group
# — CPU-based scale-out policy at 70%
# ============================================================

resource "aws_autoscaling_group" "backend" {
  name                = "${var.project_name}-${var.environment}-backend-asg"
  min_size            = var.asg_min_size
  desired_capacity    = var.asg_desired_capacity
  max_size            = var.asg_max_size

  # Spread instances across BOTH private subnets (AZ-A and AZ-B)
  vpc_zone_identifier = aws_subnet.private[*].id

  # Attach to ALB Target Group
  target_group_arns = [aws_lb_target_group.backend.arn]

  # Wait for health check before marking instance healthy
  health_check_type         = "ELB"
  health_check_grace_period = 300   # 5 min for Spring Boot startup

  launch_template {
    id      = aws_launch_template.backend.id
    version = "$Latest"
  }

  # Rolling update: replace one instance at a time
  instance_refresh {
    strategy = "Rolling"
    preferences {
      min_healthy_percentage = 50
    }
  }

  tag {
    key                 = "Name"
    value               = "${var.project_name}-${var.environment}-backend"
    propagate_at_launch = true
  }

  lifecycle {
    create_before_destroy = true
  }
}

# ── CPU Scale-Out Policy (scale out when CPU > 70%) ───────────────────────────
resource "aws_autoscaling_policy" "cpu_scale_out" {
  name                   = "${var.project_name}-${var.environment}-cpu-scale-out"
  autoscaling_group_name = aws_autoscaling_group.backend.name
  policy_type            = "TargetTrackingScaling"

  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }
    target_value = var.cpu_scale_out_threshold
  }
}
