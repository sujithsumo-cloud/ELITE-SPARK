# ============================================================
# HYDERABAD DYNAMODB TABLE
#
# Primary Region:
#   Hyderabad - ap-south-2
#
# Global Table Replica:
#   Mumbai - ap-south-1
#
# IMPORTANT:
# Mumbai replica is managed by the SECONDARY Terraform state.
# Primary Terraform must not remove or modify that replica.
# ============================================================

resource "aws_dynamodb_table" "transactions" {

  # ----------------------------------------------------------
  # TABLE
  # ----------------------------------------------------------

  name         = "FIN-TRANSACTIONS"
  billing_mode = "PAY_PER_REQUEST"


  # ----------------------------------------------------------
  # PRIMARY KEY
  # ----------------------------------------------------------

  hash_key = "transaction_id"

  attribute {
    name = "transaction_id"
    type = "S"
  }


  # ----------------------------------------------------------
  # DYNAMODB STREAMS
  #
  # Required for Global Tables replication.
  # ----------------------------------------------------------

  stream_enabled   = true
  stream_view_type = "NEW_AND_OLD_IMAGES"


  # ----------------------------------------------------------
  # POINT-IN-TIME RECOVERY
  # ----------------------------------------------------------

  point_in_time_recovery {
    enabled = true
  }


  # ----------------------------------------------------------
  # SERVER-SIDE ENCRYPTION
  # ----------------------------------------------------------

  server_side_encryption {
    enabled = true
  }


  # ----------------------------------------------------------
  # TERRAFORM GLOBAL TABLE PROTECTION
  #
  # The Mumbai replica is managed in:
  #
  # terraform\secondary\dynamodb-replica.tf
  #
  # Therefore the primary Terraform state must ignore changes
  # to the replica block.
  # ----------------------------------------------------------

  lifecycle {
    ignore_changes = [
      replica
    ]
  }


  # ----------------------------------------------------------
  # TAGS
  # ----------------------------------------------------------

  tags = {
    Name        = "FIN-TRANSACTIONS"
    Application = "finance-app"
  }
}