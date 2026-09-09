import os
import uuid
from datetime import datetime, timezone
from decimal import Decimal

import boto3
from flask import Flask, jsonify, redirect, render_template, request, url_for


app = Flask(__name__)

# ============================================================
# APPLICATION CONFIGURATION
# ============================================================

APP_REGION = os.getenv("APP_REGION", "LOCAL")
AWS_REGION = os.getenv("AWS_REGION", "ap-south-2")
DYNAMODB_TABLE = os.getenv("DYNAMODB_TABLE", "FIN-TRANSACTIONS")


# ============================================================
# DYNAMODB CONNECTION
#
# On EC2, boto3 automatically receives temporary credentials
# from APP-EC2-ROLE through the instance profile.
# ============================================================

dynamodb = boto3.resource(
    "dynamodb",
    region_name=AWS_REGION
)

table = dynamodb.Table(DYNAMODB_TABLE)


# ============================================================
# HELPER
# Convert DynamoDB Decimal values into normal JSON values.
# ============================================================

def serialize_transaction(transaction):
    result = {}

    for key, value in transaction.items():
        if isinstance(value, Decimal):
            result[key] = float(value)
        else:
            result[key] = value

    return result


# ============================================================
# HOME PAGE
# ============================================================

@app.route("/")
def home():
    response = table.scan()
    transactions = response.get("Items", [])

    # DynamoDB Scan does not guarantee order.
    # Sort newest transactions first for the dashboard.
    transactions.sort(
        key=lambda item: item.get("timestamp", ""),
        reverse=True
    )

    return render_template(
        "index.html",
        transactions=transactions,
        region=APP_REGION
    )


# ============================================================
# CREATE TRANSACTION
# ============================================================

@app.route("/create", methods=["POST"])
def create_transaction():
    customer_id = request.form.get("customer_id", "").strip()
    amount = request.form.get("amount", "").strip()
    transaction_type = request.form.get("transaction_type", "").strip()

    transaction = {
        "transaction_id": f"TXN-{uuid.uuid4().hex[:12].upper()}",
        "customer_id": customer_id,
        "amount": Decimal(amount),
        "type": transaction_type,
        "status": "SUCCESS",
        "timestamp": datetime.now(timezone.utc).isoformat(),
        "region": APP_REGION
    }

    table.put_item(Item=transaction)

    return redirect(url_for("home"))


# ============================================================
# TRANSACTIONS API
# ============================================================

@app.route("/transactions")
def get_transactions():
    response = table.scan()
    transactions = response.get("Items", [])

    transactions.sort(
        key=lambda item: item.get("timestamp", ""),
        reverse=True
    )

    transactions = [
        serialize_transaction(transaction)
        for transaction in transactions
    ]

    return jsonify(transactions)


# ============================================================
# APPLICATION HEALTH CHECK
# ============================================================

@app.route("/health")
def health():
    return jsonify({
        "application": "finance-app",
        "region": APP_REGION,
        "status": "healthy"
    })


# ============================================================
# LOCAL DEVELOPMENT
# ============================================================

if __name__ == "__main__":
    app.run(
        host="0.0.0.0",
        port=5000,
        debug=True
    )