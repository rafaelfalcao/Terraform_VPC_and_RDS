terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      shared_credentials_file = "$HOME/.aws/credentials"
    }
  }

}