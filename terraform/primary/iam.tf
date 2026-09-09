# ============================================================
# APPLICATION EC2 IAM
#
# Shared application runtime identity for:
#   Hyderabad primary  - ap-south-2
#   Mumbai DR          - ap-south-1
#
# EC2 instances use:
#   APP-EC2-PROFILE
#        ↓
#   APP-EC2-ROLE
#
# Permissions:
#   - Pull finance-app Docker images from ECR
#   - Read/write FIN-TRANSACTIONS DynamoDB Global Table
# ============================================================


# ------------------------------------------------------------
# CURRENT AWS ACCOUNT
# ------------------------------------------------------------

data "aws_caller_identity" "current" {}


# ------------------------------------------------------------
# EC2 TRUST POLICY
# ------------------------------------------------------------

data "aws_iam_policy_document" "app_ec2_trust" {

  statement {
    effect = "Allow"

    principals {
      type = "Service"

      identifiers = [
        "ec2.amazonaws.com"
      ]
    }

    actions = [
      "sts:AssumeRole"
    ]
  }
}


# ------------------------------------------------------------
# EC2 IAM ROLE
# ------------------------------------------------------------

resource "aws_iam_role" "app_ec2_role" {

  name = "APP-EC2-ROLE"

  assume_role_policy = data.aws_iam_policy_document.app_ec2_trust.json

  tags = {
    Name        = "APP-EC2-ROLE"
    Application = "finance-app"
  }
}


# ------------------------------------------------------------
# EC2 INSTANCE PROFILE
# ------------------------------------------------------------

resource "aws_iam_instance_profile" "app_ec2_profile" {

  name = "APP-EC2-PROFILE"

  role = aws_iam_role.app_ec2_role.name
}


# ============================================================
# ECR PULL POLICY
#
# EC2 must first request a temporary ECR authorization token.
#
# Then it can pull finance-app:v2 from:
#
# Hyderabad ECR
#   ap-south-2
#
# Mumbai ECR
#   ap-south-1
# ============================================================

resource "aws_iam_role_policy" "app_ec2_ecr_pull" {

  name = "APP-EC2-ECR-PULL"

  role = aws_iam_role.app_ec2_role.id

  policy = jsonencode({

    Version = "2012-10-17"

    Statement = [

      # ------------------------------------------------------
      # ECR LOGIN TOKEN
      # ------------------------------------------------------

      {
        Sid    = "ECRAuthorization"
        Effect = "Allow"

        Action = [
          "ecr:GetAuthorizationToken"
        ]

        Resource = "*"
      },

      # ------------------------------------------------------
      # ECR IMAGE PULL
      #
      # Allow the EC2 application instances to pull the
      # finance-app image from either AWS Region.
      # ------------------------------------------------------

      {
        Sid    = "PullFinanceApplicationImage"
        Effect = "Allow"

        Action = [
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage"
        ]

        Resource = [

          "arn:aws:ecr:ap-south-2:${data.aws_caller_identity.current.account_id}:repository/finance-app",

          "arn:aws:ecr:ap-south-1:${data.aws_caller_identity.current.account_id}:repository/finance-app"
        ]
      }
    ]
  })
}


# ============================================================
# DYNAMODB APPLICATION POLICY
#
# FIN-TRANSACTIONS is now a DynamoDB Global Table:
#
#   Hyderabad ap-south-2
#            ↕
#   Mumbai    ap-south-1
#
# Each regional application uses its LOCAL DynamoDB endpoint.
# ============================================================

resource "aws_iam_role_policy" "app_ec2_dynamodb" {

  name = "APP-EC2-DYNAMODB"

  role = aws_iam_role.app_ec2_role.id

  policy = jsonencode({

    Version = "2012-10-17"

    Statement = [

      {
        Sid    = "FinanceTransactionsAccess"
        Effect = "Allow"

        Action = [
          "dynamodb:GetItem",
          "dynamodb:PutItem",
          "dynamodb:UpdateItem",
          "dynamodb:Scan",
          "dynamodb:Query"
        ]

        Resource = [

          "arn:aws:dynamodb:ap-south-2:${data.aws_caller_identity.current.account_id}:table/FIN-TRANSACTIONS",

          "arn:aws:dynamodb:ap-south-1:${data.aws_caller_identity.current.account_id}:table/FIN-TRANSACTIONS"
        ]
      }
    ]
  })
}