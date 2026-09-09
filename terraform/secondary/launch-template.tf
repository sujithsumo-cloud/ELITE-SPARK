# ============================================================
# MUMBAI APPLICATION LAUNCH TEMPLATE
#
# Region:
#   Mumbai - ap-south-1
#
# Purpose:
#   Launch private EC2 instances running finance-app:v2
#
# Runtime dependencies:
#   - Mumbai ECR
#   - Mumbai DynamoDB Global Table replica
#   - APP-EC2-PROFILE
# ============================================================

resource "aws_launch_template" "app" {

  name_prefix = "MUM-APP-LT-"

  image_id      = "ami-05f2a6fd23dbbd066"
  instance_type = "t3.micro"

  # ----------------------------------------------------------
  # IAM INSTANCE PROFILE
  #
  # Existing global IAM profile created by primary Terraform.
  # ----------------------------------------------------------

  iam_instance_profile {
    name = "APP-EC2-PROFILE"
  }

  # ----------------------------------------------------------
  # PRIVATE NETWORK INTERFACE
  # ----------------------------------------------------------

  network_interfaces {
    associate_public_ip_address = false

    security_groups = [
      aws_security_group.app.id
    ]
  }

  # ----------------------------------------------------------
  # IMDSv2
  #
  # Hop limit 2 allows the Docker container to obtain the
  # EC2 IAM role credentials through IMDSv2.
  # ----------------------------------------------------------

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 2
  }

  # ----------------------------------------------------------
  # APPLICATION BOOTSTRAP
  # ----------------------------------------------------------

  user_data = base64encode(<<-EOF
    #!/bin/bash
    set -e

    REGION="ap-south-1"
    ACCOUNT_ID="257074875139"

    REGISTRY="$ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com"
    IMAGE="$REGISTRY/finance-app:v2"

    echo "Starting Mumbai finance application bootstrap"

    # Start Docker
    systemctl enable docker
    systemctl start docker

    # Login to Mumbai ECR using the EC2 IAM role
    aws ecr get-login-password --region "$REGION" | \
      docker login \
      --username AWS \
      --password-stdin "$REGISTRY"

    # Pull the exact application image
    docker pull "$IMAGE"

    # Remove old container if one exists
    docker rm -f finance-app || true

    # Start finance application
    docker run -d \
      --name finance-app \
      --restart unless-stopped \
      -p 5000:5000 \
      -e APP_REGION=MUMBAI \
      -e AWS_REGION=ap-south-1 \
      -e DYNAMODB_TABLE=FIN-TRANSACTIONS \
      "$IMAGE"

    echo "Mumbai finance application started"
  EOF
  )

  # ----------------------------------------------------------
  # RESOURCE TAGS
  # ----------------------------------------------------------

  tag_specifications {
    resource_type = "instance"

    tags = {
      Name        = "MUM-APP-EC2"
      Application = "finance-app"
      Environment = "Disaster-Recovery"
      Region      = "Mumbai"
    }
  }

  tag_specifications {
    resource_type = "volume"

    tags = {
      Name        = "MUM-APP-EBS"
      Application = "finance-app"
      Environment = "Disaster-Recovery"
    }
  }

  tags = {
    Name        = "MUM-APP-LT"
    Application = "finance-app"
  }
}