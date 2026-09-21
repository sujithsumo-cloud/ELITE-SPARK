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
# Required only so Terraform can read the Mumbai ALB.
# Route 53 itself is a global AWS service.
# ------------------------------------------------------------

provider "aws" {
  alias  = "mumbai"
  region = "ap-south-1"
}


# ------------------------------------------------------------
# EXISTING PUBLIC HOSTED ZONE
# The hosted zone is shared/existing infrastructure.
# Terraform reads it but does not create or destroy it.
# ------------------------------------------------------------

data "aws_route53_zone" "elite_spark" {
  name         = "best.2bd.net."
  private_zone = false
}


# ------------------------------------------------------------
# EXISTING MUMBAI ALB
# Deploy the secondary Terraform stack before the primary stack
# so this lookup succeeds when Route 53 records are created.
# ------------------------------------------------------------

data "aws_lb" "mum" {
  provider = aws.mumbai
  name     = "MUM-ALB"
}


# ============================================================
# PRIMARY FAILOVER RECORD
# HYDERABAD
# The Hyderabad ALB is created by this Terraform stack, so use
# the resource directly rather than looking it up as existing.
# ============================================================

resource "aws_route53_record" "finance_primary" {
  zone_id = data.aws_route53_zone.elite_spark.zone_id
  name    = "finance.best.2bd.net"
  type    = "A"

  set_identifier = "HYDERABAD-PRIMARY"

  failover_routing_policy {
    type = "PRIMARY"
  }

  alias {
    name                   = aws_lb.app.dns_name
    zone_id                = aws_lb.app.zone_id
    evaluate_target_health = true
  }
}


# ============================================================
# SECONDARY FAILOVER RECORD
# MUMBAI
# ============================================================

resource "aws_route53_record" "finance_secondary" {
  zone_id = data.aws_route53_zone.elite_spark.zone_id
  name    = "finance.best.2bd.net"
  type    = "A"

  set_identifier = "MUMBAI-SECONDARY"

  failover_routing_policy {
    type = "SECONDARY"
  }

  alias {
    name                   = data.aws_lb.mum.dns_name
    zone_id                = data.aws_lb.mum.zone_id
    evaluate_target_health = true
  }
}
