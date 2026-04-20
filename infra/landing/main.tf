terraform {
  required_version = ">= 1.5"

  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 4.40"
    }
  }

  backend "s3" {
    bucket         = "alpha-terraform-state-773469078444"
    key            = "planyr-landing/terraform.tfstate"
    region         = "us-west-2"
    dynamodb_table = "alpha-terraform-locks"
    encrypt        = true
  }
}

provider "cloudflare" {
  api_token = var.cloudflare_api_token
}

data "cloudflare_zone" "planyr" {
  name = var.domain
}
