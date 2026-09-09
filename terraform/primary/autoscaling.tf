# ============================================================
# HYDERABAD APPLICATION AUTO SCALING GROUP
#
# Runs application EC2 instances across both Hyderabad
# private subnets / Availability Zones.
# ============================================================

resource "aws_autoscaling_group" "app" {
  name = "HYD-APP-ASG"

  min_size         = 2
  desired_capacity = 2
  max_size         = 4

  # ----------------------------------------------------------
  # PRIVATE MULTI-AZ PLACEMENT
  # ----------------------------------------------------------

  vpc_zone_identifier = [
    aws_subnet.private_a.id,
    aws_subnet.private_b.id
  ]

  # ----------------------------------------------------------
  # LAUNCH TEMPLATE
  # Uses the latest version created by Terraform.
  # ----------------------------------------------------------

  launch_template {
    id      = aws_launch_template.app.id
    version = aws_launch_template.app.latest_version
  }

  # ----------------------------------------------------------
  # TARGET GROUP REGISTRATION
  # ----------------------------------------------------------

  target_group_arns = [
    aws_lb_target_group.app.arn
  ]

  # ----------------------------------------------------------
  # HEALTH CHECK
  # ----------------------------------------------------------

  health_check_type         = "ELB"
  health_check_grace_period = 180

  # ----------------------------------------------------------
  # INSTANCE TAGS
  # ----------------------------------------------------------

  tag {
    key                 = "Name"
    value               = "HYD-APP-EC2"
    propagate_at_launch = true
  }

  tag {
    key                 = "Project"
    value               = "Multi-Region-DR"
    propagate_at_launch = true
  }

  tag {
    key                 = "Environment"
    value               = "Primary"
    propagate_at_launch = true
  }

  tag {
    key                 = "Region"
    value               = "Hyderabad"
    propagate_at_launch = true
  }

  tag {
    key                 = "ManagedBy"
    value               = "Terraform"
    propagate_at_launch = true
  }
}
# ============================================================
# CPU TARGET TRACKING SCALING POLICY
#
# Keeps average ASG CPU near 60 percent.
# ASG can scale between min_size and max_size.
# ============================================================

resource "aws_autoscaling_policy" "cpu_target_tracking" {
  name                   = "HYD-APP-CPU-TARGET-TRACKING"
  autoscaling_group_name = aws_autoscaling_group.app.name
  policy_type            = "TargetTrackingScaling"

  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }

    target_value = 60.0
  }
}