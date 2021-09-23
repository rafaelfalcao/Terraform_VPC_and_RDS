module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = "VirtualPrivateCloud"
  #Classless Inter-Domain Routing 
  #IPv4 addresses for the vpc
  cidr = "192.168.0.0/16"

    #availability zones
  azs             = ["eu-west-2a" , "eu-west-2b"] //, "eu-west-2c"]

  #SUBNETS - range of ip addresses in the vpc - subset of CIDR

  private_subnets = ["192.168.1.0/24" , "192.168.2.0/24", "192.168.3.0/24"]

  #to route to an internet gateway
  #needs public ipv4 or elastic ip 
  public_subnets  = ["192.168.100.0/24"] //, "10.0.102.0/24", "10.0.103.0/24"]

  #traffic routed to a vpn gateway for a site-to-site vpn connection
  #enables access to your remote network from your VPC by creating an AWS Site-to-Site VPN (Site-to-Site VPN) connection, 
  #and configuring routing to pass traffic through the connection. 
  enable_vpn_gateway = true

  enable_nat_gateway = true
  
}

############################################  EC2 INSTANCE ##################################################
resource "aws_instance" "myEC2" {
    ami = "ami-069bc9cfa21be900c"
    instance_type= "t2.micro"
    subnet_id     = module.vpc.public_subnets[0]
    key_name = "credentials"
    associate_public_ip_address = true
    vpc_security_group_ids = [ aws_security_group.ec2-sg.id ]

    //passing user data to the instance 
    //that can be used to perform common automated 
    //configuration tasks and even run scripts after the instance starts. 
    user_data = <<-EOF
                #!/bin/bash
                yum install mysql
              EOF
}

############################################  EC2 SECURITY GROUP ##################################################
resource "aws_security_group" "ec2-sg" {
    name = "security_group"
    description = "allow outside access to EC2"
    vpc_id = module.vpc.vpc_id

    #traffic to enter
    ingress {
        protocol = -1 #all protocols
        from_port = 0
        to_port = 0
        cidr_blocks =["0.0.0.0/0"]
    }
     
    #traffic to exit
    egress {
        protocol = -1 #all protocols
        from_port = 0
        to_port = 0
        cidr_blocks =["0.0.0.0/0"]
    }
}

#elastic IP

#RDS
resource "aws_db_instance" "myDB" {
    allocated_storage = 50
    identifier = "rdsinstance"
    storage_type = "gp2"
    engine = "mysql"
    engine_version = "5.7"
    instance_class = "db.db.t2.micro" #free tier
    name = "rds"
    username = "dbadmin"
    password = "dbadmin"
    parameter_group_name = "default.mysql5.7"
}




