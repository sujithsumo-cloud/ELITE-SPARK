# ============================================================
# MUMBAI DYNAMODB GLOBAL TABLE REPLICA
#
# Source:
#   Hyderabad ap-south-2
#
# Replica:
#   Mumbai ap-south-1
# ============================================================

resource "aws_dynamodb_table_replica" "transactions_mumbai" {
  global_table_arn = "arn:aws:dynamodb:ap-south-2:257074875139:table/FIN-TRANSACTIONS"

  point_in_time_recovery = true

  tags = {
    Name        = "FIN-TRANSACTIONS"
    Application = "finance-app"
    Region      = "Mumbai"
  }
}