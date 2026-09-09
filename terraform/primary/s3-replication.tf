# ============================================================
# ELITE SPARK
# S3 CROSS-REGION REPLICATION
#
# SOURCE
#   Hyderabad - ap-south-2
#   elite-spark-finance-hyd-78b15ff1399189995156c8a3a2
#
# DESTINATION
#   Mumbai - ap-south-1
#   elite-spark-finance-mum-a65b21c5cc2f0c35
#
# FLOW
#
# HYD S3
#    ↓
# ELITE-SPARK-S3-CRR-ROLE
#    ↓
# S3 Cross-Region Replication
#    ↓
# MUM S3
# ============================================================


# ------------------------------------------------------------
# S3 REPLICATION ROLE TRUST POLICY
#
# Amazon S3 is allowed to assume this role.
# ------------------------------------------------------------

data "aws_iam_policy_document" "s3_crr_assume_role" {

  statement {

    effect = "Allow"

    principals {
      type = "Service"

      identifiers = [
        "s3.amazonaws.com"
      ]
    }

    actions = [
      "sts:AssumeRole"
    ]
  }
}


# ------------------------------------------------------------
# S3 REPLICATION IAM ROLE
# ------------------------------------------------------------

resource "aws_iam_role" "s3_crr" {

  name = "ELITE-SPARK-S3-CRR-ROLE"

  assume_role_policy = data.aws_iam_policy_document.s3_crr_assume_role.json

  tags = {
    Name        = "ELITE-SPARK-S3-CRR-ROLE"
    Project     = "Multi-Region-DR"
    Application = "finance-app"
    Purpose     = "S3-Cross-Region-Replication"
  }
}


# ------------------------------------------------------------
# REPLICATION ROLE PERMISSIONS
# ------------------------------------------------------------

resource "aws_iam_role_policy" "s3_crr" {

  name = "ELITE-SPARK-S3-CRR-POLICY"

  role = aws_iam_role.s3_crr.id

  policy = jsonencode({

    Version = "2012-10-17"

    Statement = [

      # ------------------------------------------------------
      # READ SOURCE BUCKET CONFIGURATION
      # ------------------------------------------------------

      {
        Sid    = "ReadHyderabadSourceBucket"
        Effect = "Allow"

        Action = [
          "s3:GetReplicationConfiguration",
          "s3:ListBucket"
        ]

        Resource = [
          "arn:aws:s3:::elite-spark-finance-hyd-78b15ff1399189995156c8a3a2"
        ]
      },


      # ------------------------------------------------------
      # READ SOURCE OBJECT VERSIONS
      # ------------------------------------------------------

      {
        Sid    = "ReadHyderabadSourceObjects"
        Effect = "Allow"

        Action = [
          "s3:GetObjectVersionForReplication",
          "s3:GetObjectVersionAcl",
          "s3:GetObjectVersionTagging"
        ]

        Resource = [
          "arn:aws:s3:::elite-spark-finance-hyd-78b15ff1399189995156c8a3a2/*"
        ]
      },


      # ------------------------------------------------------
      # WRITE REPLICAS TO MUMBAI
      # ------------------------------------------------------

      {
        Sid    = "ReplicateObjectsToMumbai"
        Effect = "Allow"

        Action = [
          "s3:ReplicateObject",
          "s3:ReplicateDelete",
          "s3:ReplicateTags"
        ]

        Resource = [
          "arn:aws:s3:::elite-spark-finance-mum-a65b21c5cc2f0c35/*"
        ]
      }
    ]
  })
}


# ------------------------------------------------------------
# S3 CROSS-REGION REPLICATION CONFIGURATION
# ------------------------------------------------------------

resource "aws_s3_bucket_replication_configuration" "finance_crr" {

  bucket = aws_s3_bucket.finance.id

  role = aws_iam_role.s3_crr.arn

  depends_on = [
    aws_s3_bucket_versioning.finance,
    aws_iam_role_policy.s3_crr
  ]


  # ----------------------------------------------------------
  # HYDERABAD → MUMBAI
  # ----------------------------------------------------------

  rule {

    id       = "HYD-TO-MUM-CRR"
    priority = 1
    status   = "Enabled"

    # Empty filter = replicate all new objects.
    filter {}


    # --------------------------------------------------------
    # ACCIDENTAL DELETE PROTECTION
    #
    # We intentionally do NOT replicate delete markers.
    #
    # If somebody accidentally deletes an object in Hyderabad,
    # the Mumbai DR copy remains directly available.
    # --------------------------------------------------------

    delete_marker_replication {
      status = "Disabled"
    }


    # --------------------------------------------------------
    # DESTINATION
    # --------------------------------------------------------

    destination {

      bucket = "arn:aws:s3:::elite-spark-finance-mum-a65b21c5cc2f0c35"

      storage_class = "STANDARD"
    }
  }
}