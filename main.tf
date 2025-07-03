terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.68.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}


# Elastic IP for n8n EC2
resource "aws_eip" "n8n_eip" {
  instance = aws_instance.n8n.id
}
