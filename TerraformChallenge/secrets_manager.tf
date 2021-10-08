/*  ############################################  RDS SECRET ##################################################

  resource "aws_secretsmanager_secret" "rds_secret" {
    name = "rds_admin"
    description = "rds admin password"

  }

  resource "aws_secretsmanager_secret_version" "rdssecretversion" {
    secret_id = aws_secretsmanager_secret.rds_secret.id
    secret_string =  random_password.rdspassword.result
  }

 ############################################  RDS PASSWORD ##################################################
 
resource "random_password" "rdspassword" {
  length = 12
  special = true
} 
 */

data "aws_secretsmanager_secret_version" "rds_secret_version"{
  secret_id = data.aws_secretsmanager_secret.rds_password.id
  
}

data "aws_secretsmanager_secret" "rds_password" {
  name = "rds_admin"
}

output "rds_password_output" {
  //value = data.aws_secretsmanager_secret_version.rds_secret_version.secret_string
  sensitive = true
  value = base64encode(data.aws_secretsmanager_secret_version.rds_secret_version.secret_string)
}