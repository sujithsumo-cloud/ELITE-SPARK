# ============================================================
# ELITE SPARK
# ROUTE 53 MULTI-REGION FAILOVER
#
# DNS:
#   finance.best.2bd.net
#
# PRIMARY:
#   Hyderabad ALB - ap-south-2
#
# SECONDARY:
#   Mumbai ALB - ap-south-1
# ============================================================


# ------------------------------------------------------------
# MUMBAI PROVIDER
#
# Required only so Terraform can read the Mumbai ALB.
# Route 53 itself is a global AWS service.
# ------------------------------------------------------------

provider "aws" {
  alias  = "mumbai"
  region = "ap-south-1"
}


# ------------------------------------------------------------
# EXISTING PUBLIC HOSTED ZONE
#
# We created this hosted zone manually.
# Terraform only READS it.
# Terraform will NOT recreate or destroy it.
# ------------------------------------------------------------

data "aws_route53_zone" "elite_spark" {
  name         = "best.2bd.net."
  private_zone = false
}


# ------------------------------------------------------------
# EXISTING HYDERABAD ALB
# ------------------------------------------------------------

data "aws_lb" "hyd" {
  name = "HYD-ALB"
}


# ------------------------------------------------------------
# EXISTING MUMBAI ALB
# ------------------------------------------------------------

data "aws_lb" "mum" {
  provider = aws.mumbai

  name = "MUM-ALB"
}


# ============================================================
# PRIMARY FAILOVER RECORD
# HYDERABAD
# ============================================================

resource "aws_route53_record" "finance_primary" {

  zone_id = data.aws_route53_zone.elite_spark.zone_id

  name = "finance.best.2bd.net"

  type = "A"

  set_identifier = "HYDERABAD-PRIMARY"


  failover_routing_policy {
    type = "PRIMARY"
  }


  alias {

    name = data.aws_lb.hyd.dns_name

    zone_id = data.aws_lb.hyd.zone_id

    # Route 53 evaluates the health of the ALB targets.
    evaluate_target_health = true
  }
}


# ============================================================
# SECONDARY FAILOVER RECORD
# MUMBAI
# ============================================================

resource "aws_route53_record" "finance_secondary" {

  zone_id = data.aws_route53_zone.elite_spark.zone_id

  name = "finance.best.2bd.net"

  type = "A"

  set_identifier = "MUMBAI-SECONDARY"


  failover_routing_policy {
    type = "SECONDARY"
  }


  alias {

    name = data.aws_lb.mum.dns_name

    zone_id = data.aws_lb.mum.zone_id

    # Mumbai must also have healthy ALB targets.
    evaluate_target_health = true
  }
}