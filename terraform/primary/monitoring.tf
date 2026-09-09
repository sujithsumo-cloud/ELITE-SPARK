# ============================================================
# SNS ALERT TOPIC
# ============================================================

resource "aws_sns_topic" "alerts" {
  name = "HYD-ALERTS"

  tags = {
    Name = "HYD-ALERTS"
  }
}


# ============================================================
# CLOUDWATCH ALARM - HIGH CPU
#
# Monitors average CPU usage across instances belonging
# to HYD-APP-ASG.
# ============================================================

resource "aws_cloudwatch_metric_alarm" "high_cpu" {
  alarm_name        = "HYD-APP-HIGH-CPU"
  alarm_description = "Application Auto Scaling Group CPU is above 70 percent"

  namespace   = "AWS/EC2"
  metric_name = "CPUUtilization"

  statistic = "Average"
  period    = 300

  evaluation_periods = 2
  threshold          = 70

  comparison_operator = "GreaterThanOrEqualToThreshold"

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.app.name
  }

  treat_missing_data = "notBreaching"

  alarm_actions = [
    aws_sns_topic.alerts.arn
  ]

  ok_actions = [
    aws_sns_topic.alerts.arn
  ]

  tags = {
    Name = "HYD-APP-HIGH-CPU"
  }
}


# ============================================================
# CLOUDWATCH ALARM - UNHEALTHY ALB TARGET
#
# Alarm if at least one target becomes unhealthy.
# ============================================================

resource "aws_cloudwatch_metric_alarm" "unhealthy_targets" {
  alarm_name        = "HYD-APP-UNHEALTHY-TARGET"
  alarm_description = "One or more application targets are unhealthy"

  namespace   = "AWS/ApplicationELB"
  metric_name = "UnHealthyHostCount"

  statistic = "Maximum"
  period    = 60

  evaluation_periods = 1
  threshold          = 1

  comparison_operator = "GreaterThanOrEqualToThreshold"

  dimensions = {
    LoadBalancer = aws_lb.app.arn_suffix
    TargetGroup  = aws_lb_target_group.app.arn_suffix
  }

  treat_missing_data = "notBreaching"

  alarm_actions = [
    aws_sns_topic.alerts.arn
  ]

  ok_actions = [
    aws_sns_topic.alerts.arn
  ]

  tags = {
    Name = "HYD-APP-UNHEALTHY-TARGET"
  }
}


# ============================================================
# CLOUDWATCH ALARM - DYNAMODB SYSTEM ERRORS
# ============================================================

resource "aws_cloudwatch_metric_alarm" "dynamodb_errors" {
  alarm_name        = "HYD-DYNAMODB-SYSTEM-ERROR"
  alarm_description = "DynamoDB FIN-TRANSACTIONS reported system errors"

  namespace   = "AWS/DynamoDB"
  metric_name = "SystemErrors"

  statistic = "Sum"
  period    = 60

  evaluation_periods = 1
  threshold          = 1

  comparison_operator = "GreaterThanOrEqualToThreshold"

  dimensions = {
    TableName = aws_dynamodb_table.transactions.name
  }

  treat_missing_data = "notBreaching"

  alarm_actions = [
    aws_sns_topic.alerts.arn
  ]

  ok_actions = [
    aws_sns_topic.alerts.arn
  ]

  tags = {
    Name = "HYD-DYNAMODB-SYSTEM-ERROR"
  }
}


# ============================================================
# CLOUDWATCH DASHBOARD
# ============================================================

resource "aws_cloudwatch_dashboard" "dr_dashboard" {
  dashboard_name = "HYD-DR-DASHBOARD"

  dashboard_body = jsonencode({
    widgets = [

      # ------------------------------------------------------
      # AUTO SCALING GROUP CPU
      # ------------------------------------------------------

      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 12
        height = 6

        properties = {
          title  = "HYD Application CPU Utilization"
          region = "ap-south-2"
          period = 300
          stat   = "Average"

          metrics = [
            [
              "AWS/EC2",
              "CPUUtilization",
              "AutoScalingGroupName",
              aws_autoscaling_group.app.name
            ]
          ]
        }
      },

      # ------------------------------------------------------
      # ALB TARGET HEALTH
      # ------------------------------------------------------

      {
        type   = "metric"
        x      = 12
        y      = 0
        width  = 12
        height = 6

        properties = {
          title  = "HYD ALB Target Health"
          region = "ap-south-2"
          period = 60
          stat   = "Average"

          metrics = [
            [
              "AWS/ApplicationELB",
              "HealthyHostCount",
              "LoadBalancer",
              aws_lb.app.arn_suffix,
              "TargetGroup",
              aws_lb_target_group.app.arn_suffix
            ],
            [
              ".",
              "UnHealthyHostCount",
              ".",
              ".",
              ".",
              "."
            ]
          ]
        }
      },

      # ------------------------------------------------------
      # DYNAMODB ERRORS / THROTTLING
      # ------------------------------------------------------

      {
        type   = "metric"
        x      = 0
        y      = 6
        width  = 12
        height = 6

        properties = {
          title  = "FIN-TRANSACTIONS DynamoDB"
          region = "ap-south-2"
          period = 60
          stat   = "Sum"

          metrics = [
            [
              "AWS/DynamoDB",
              "SystemErrors",
              "TableName",
              aws_dynamodb_table.transactions.name
            ],
            [
              ".",
              "ThrottledRequests",
              ".",
              "."
            ]
          ]
        }
      },

      # ------------------------------------------------------
      # ALB REQUEST COUNT
      # ------------------------------------------------------

      {
        type   = "metric"
        x      = 12
        y      = 6
        width  = 12
        height = 6

        properties = {
          title  = "HYD ALB Request Count"
          region = "ap-south-2"
          period = 60
          stat   = "Sum"

          metrics = [
            [
              "AWS/ApplicationELB",
              "RequestCount",
              "LoadBalancer",
              aws_lb.app.arn_suffix
            ]
          ]
        }
      }
    ]
  })
}