# ============================================================
# MUMBAI APPLICATION AUTO SCALING GROUP
#
# Warm standby DR design:
#
# Minimum = 1
# Desired = 1
# Maximum = 2
#
# Normally:
#   1 EC2 instance to control cost.
#
# During DR / scaling test:
#   Can increase to 2.
# ============================================================

resource "aws_autoscaling_group" "app" {

  name = "MUM-APP-ASG"

  min_size         = 1
  desired_capacity = 1
  max_size         = 2

  vpc_zone_identifier = [
    aws_subnet.private_a.id,
    aws_subnet.private_b.id
  ]

  health_check_type         = "ELB"
  health_check_grace_period = 180

  target_group_arns = [
    aws_lb_target_group.app.arn
  ]

  launch_template {
    id = aws_launch_template.app.id

    version = aws_launch_template.app.latest_version
  }

  tag {
    key                 = "Name"
    value               = "MUM-APP-EC2"
    propagate_at_launch = true
  }

  tag {
    key                 = "Application"
    value               = "finance-app"
    propagate_at_launch = true
  }

  tag {
    key                 = "Environment"
    value               = "Disaster-Recovery"
    propagate_at_launch = true
  }

  tag {
    key                 = "Region"
    value               = "Mumbai"
    propagate_at_launch = true
  }

  lifecycle {
    create_before_destroy = true
  }
}