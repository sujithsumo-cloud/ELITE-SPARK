# ============================================================
# HYDERABAD APPLICATION LAUNCH TEMPLATE
# ============================================================

resource "aws_launch_template" "app" {
  name_prefix   = "HYD-APP-LT-"
  image_id      = "ami-0f30128d8d8cc0103"
  instance_type = "t3.micro"

  # ----------------------------------------------------------
  # EC2 IAM INSTANCE PROFILE
  # ----------------------------------------------------------

  iam_instance_profile {
    name = aws_iam_instance_profile.app_ec2_profile.name
  }

  # ----------------------------------------------------------
  # APPLICATION SECURITY GROUP
  # ----------------------------------------------------------

  vpc_security_group_ids = [
    aws_security_group.app.id
  ]

  # ----------------------------------------------------------
  # IMDSv2
  # Hop limit 2 allows the Docker container to obtain
  # temporary credentials from the EC2 IAM role.
  # ----------------------------------------------------------

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 2
  }

  # ----------------------------------------------------------
  # USER DATA
  # Start Docker -> Login to ECR -> Pull v2 ->
  # Run DynamoDB-backed finance application
  # ----------------------------------------------------------

  user_data = base64encode(<<-EOF
    #!/bin/bash
    set -e

    REGION="ap-south-2"
    REGISTRY="257074875139.dkr.ecr.ap-south-2.amazonaws.com"
    IMAGE="$REGISTRY/finance-app:v2"

    systemctl enable docker
    systemctl start docker

    aws ecr get-login-password --region "$REGION" | \
      docker login --username AWS --password-stdin "$REGISTRY"

    docker pull "$IMAGE"

    docker rm -f finance-app 2>/dev/null || true

    docker run -d \
      --name finance-app \
      --restart unless-stopped \
      -p 5000:5000 \
      -e APP_REGION=HYDERABAD \
      -e AWS_REGION=ap-south-2 \
      -e DYNAMODB_TABLE=FIN-TRANSACTIONS \
      "$IMAGE"
  EOF
  )

  # ----------------------------------------------------------
  # INSTANCE TAG
  # ----------------------------------------------------------

  tag_specifications {
    resource_type = "instance"

    tags = {
      Name = "HYD-APP-EC2"
    }
  }

  tags = {
    Name = "HYD-APP-LT"
  }
}