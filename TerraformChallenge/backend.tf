terraform {
  backend "s3"{
      bucket = "shared-tfstate-639110431478-eu-west-2"
      dynamodb_table = "tfstate-lock"
      key = "path/to/my/terraform.tfstate"
      region = "eu-west-2"
  }
}