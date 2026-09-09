provider "aws" {
  region = "ap-south-2"

  default_tags {
    tags = {
      Project     = "Multi-Region-DR"
      Environment = "Primary"
      Region      = "Hyderabad"
      ManagedBy   = "Terraform"
    }
  }
}