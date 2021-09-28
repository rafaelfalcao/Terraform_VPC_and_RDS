provider "aws" {
  profile = "terraform-ubuntu"
  region  = "eu-west-2"
}


variable "dbname" {
  description = "RDS db_name"
} 

variable "db_username" {
  description = "RDS db_username"
  sensitive = true
}

variable "db_password" {
  description = "RDS db_password"
  sensitive = true
}

/* 

variable "instance_type" {
  description = "AWS instance_type"
}

variable "rds_instance_identifier_name" {
  description = "RDS instance_identifier_name"
}

variable "rds_cluster_identifier_name" {
  description = "RDS cluster_identifier_name"
} */ 