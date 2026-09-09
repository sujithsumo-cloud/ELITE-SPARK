# ============================================================
# MUMBAI DR OUTPUTS
# ============================================================


# ------------------------------------------------------------
# NETWORK
# ------------------------------------------------------------

output "dr_vpc_id" {
  value = aws_vpc.dr.id
}

output "availability_zone_a" {
  value = aws_subnet.public_a.availability_zone
}

output "availability_zone_b" {
  value = aws_subnet.public_b.availability_zone
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


# ------------------------------------------------------------
# SECURITY GROUPS
# ------------------------------------------------------------

output "mum_alb_security_group_id" {
  value = aws_security_group.alb.id
}

output "mum_app_security_group_id" {
  value = aws_security_group.app.id
}

output "mum_endpoint_security_group_id" {
  value = aws_security_group.endpoints.id
}


# ------------------------------------------------------------
# ECR
# ------------------------------------------------------------

output "mum_finance_app_ecr_url" {
  value = aws_ecr_repository.finance_app.repository_url
}


# ------------------------------------------------------------
# DYNAMODB
# ------------------------------------------------------------

output "mum_dynamodb_replica_arn" {
  value = aws_dynamodb_table_replica.transactions_mumbai.arn
}


# ------------------------------------------------------------
# LAUNCH TEMPLATE
# ------------------------------------------------------------

output "mum_launch_template_id" {
  value = aws_launch_template.app.id
}


# ------------------------------------------------------------
# AUTO SCALING
# ------------------------------------------------------------

output "mum_asg_name" {
  value = aws_autoscaling_group.app.name
}


# ------------------------------------------------------------
# LOAD BALANCER
# ------------------------------------------------------------

output "mum_alb_dns_name" {
  value = aws_lb.app.dns_name
}

output "mum_target_group_arn" {
  value = aws_lb_target_group.app.arn
}
output "mum_s3_dr_bucket_name" {
  value = aws_s3_bucket.finance_dr.bucket
}

output "mum_s3_dr_bucket_arn" {
  value = aws_s3_bucket.finance_dr.arn
}