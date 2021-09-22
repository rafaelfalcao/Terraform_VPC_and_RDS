module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = "VirtualPrivateCloud"
  #Classless Inter-Domain Routing 
  #IPv4 addresses for the vpc
  cidr = "192.168.0.0/16"

    #availability zones
  azs             = ["eu-west-2a" , "eu-west-2b"] //, "eu-west-2c"]

  #SUBNETS - range of ip addresses in the vpc - subset of CIDR

  private_subnets = ["192.168.0.1/24"] //, "10.0.2.0/24", "10.0.3.0/24"]

  #to route to an internet gateway
  #needs public ipv4 or elastic ip 
  public_subnets  = ["192.168.100.0/24"] //, "10.0.102.0/24", "10.0.103.0/24"]

  #traffic routed to a vpn gateway for a site-to-site vpn connection
  #enables access to your remote network from your VPC by creating an AWS Site-to-Site VPN (Site-to-Site VPN) connection, 
  #and configuring routing to pass traffic through the connection. 
  enable_vpn_gateway = true

  enable_nat_gateway = true
  

  }
}


# resource "aws_instance" "ec2-public" {
#     ami = "ami-069bc9cfa21be900c"
#     instance_type= "t2.micro"
#     subnet_id     = module.vpc.public_subnets
#     key_name = "credentials"
#     associate_public_ip_address = true
#     vpc_security_group_ids = [ aws_security_group.ec2-sg.id ]
   
# }

resource "aws_security_group" "ec2-sg" {
    name = "security_group"
    description = "allow outside access to EC2"
    vpc_id = module.vpc.vpc_id

    //traffic to enter
    ingress {
        protocol = -1 //all protocols
        from_port = 0
        to_port = 0
        cidr_blocks =[0.0.0.0/0]
    }

    egress {
        protocol = -1 //all protocols
        from_port = 0
        to_port = 0
        cidr_blocks =[0.0.0.0/0]
    }
}

#get mysql client
sudo apt-get update
sudo apt-get install -y mysql-client

#terraform init
#terraform fmt
#terraform validate
#terraform plan
#terraform apply 