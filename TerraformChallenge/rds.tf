################################################  RDS ########################################################3
resource "aws_db_instance" "myDB" {
  allocated_storage      = 10
  identifier             = "rdsinstance"
  engine                 = "mysql"
  engine_version         = "5.7"
  instance_class         = "db.t2.micro" #free tier
  #sets secrets from variables
  name                   = var.dbname
  username               = var.db_username

  password               = data.aws_secretsmanager_secret_version.rds_secret_version.secret_string
  parameter_group_name   = "default.mysql5.7"
  db_subnet_group_name   = aws_db_subnet_group.rds_subnet_group.name
  vpc_security_group_ids = [aws_security_group.rds-sg.id]
  
  #only use this if non prod
  skip_final_snapshot = true

  final_snapshot_identifier = "rdsinstance"
}

resource "aws_db_subnet_group" "rds_subnet_group" {
  name       = "main"
  subnet_ids = module.vpc.private_subnets

  tags = {
    Name = "My DB subnet group"
  }
}



############################################  RDS SECURITY GROUP ##################################################

resource "aws_security_group" "rds-sg" {
  name        = "rds_security_group"
  description = "allow outside access to RDS"
  vpc_id      = module.vpc.vpc_id

  #traffic to enter
  ingress {
    protocol    = "tcp" #all protocols
    from_port   = 3306
    to_port     = 3306
    security_groups = [ aws_security_group.ec2-sg.id ]
  }

  #traffic to exit - allow all 
  egress {
    protocol    = -1 #all protocols
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
}

 