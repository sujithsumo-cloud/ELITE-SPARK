output "primary_vpc_id" {
  description = "Hyderabad Primary VPC ID"
  value       = aws_vpc.primary.id
}

output "public_subnet_a_id" {
  value = aws_subnet.public_a.id
}

output "public_subnet_b_id" {
  value = aws_subnet.public_b.id
}

output "private_subnet_a_id" {
  value = aws_subnet.private_a.id
}

output "private_subnet_b_id" {
  value = aws_subnet.private_b.id
}

output "availability_zone_a" {
  value = data.aws_availability_zones.available.names[0]
}

output "availability_zone_b" {
  value = data.aws_availability_zones.available.names[1]
}
output "alb_security_group_id" {
  description = "Hyderabad ALB Security Group ID"
  value       = aws_security_group.alb.id
}

output "app_security_group_id" {
  description = "Hyderabad Application Security Group ID"
  value       = aws_security_group.app.id
}
output "finance_app_ecr_url" {
  description = "Finance Application ECR Repository URL"
  value       = aws_ecr_repository.finance_app.repository_url
}
output "app_ec2_role_name" {
  description = "IAM role used by application EC2 instances"
  value       = aws_iam_role.app_ec2_role.name
}

output "app_ec2_instance_profile_name" {
  description = "Instance profile attached to application EC2 instances"
  value       = aws_iam_instance_profile.app_ec2_profile.name
}
output "alb_dns_name" {
  description = "DNS name of the Hyderabad Application Load Balancer"
  value       = aws_lb.app.dns_name
}

output "app_target_group_arn" {
  description = "ARN of the Hyderabad application target group"
  value       = aws_lb_target_group.app.arn
}
output "app_autoscaling_group_name" {
  description = "Hyderabad application Auto Scaling Group name"
  value       = aws_autoscaling_group.app.name
}
output "finance_s3_bucket_name" {
  description = "Hyderabad finance S3 bucket name"
  value       = aws_s3_bucket.finance.bucket
}
output "sns_alert_topic_arn" {
  description = "SNS topic used for Hyderabad monitoring alerts"
  value       = aws_sns_topic.alerts.arn
}

output "cloudwatch_dashboard_name" {
  description = "CloudWatch monitoring dashboard"
  value       = aws_cloudwatch_dashboard.dr_dashboard.dashboard_name
}