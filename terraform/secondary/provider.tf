provider "aws" {
  region = "ap-south-1"

  default_tags {
    tags = {
      Project     = "Multi-Region-DR"
      Environment = "Disaster-Recovery"
      Region      = "Mumbai"
      ManagedBy   = "Terraform"
    }
  }
}