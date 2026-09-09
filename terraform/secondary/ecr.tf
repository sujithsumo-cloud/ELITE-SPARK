# ============================================================
# MUMBAI DR ECR REPOSITORY
# ============================================================

resource "aws_ecr_repository" "finance_app" {
  name                 = "finance-app"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Name = "MUM-FINANCE-ECR"
  }
}