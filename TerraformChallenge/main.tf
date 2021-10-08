module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = "VirtualPrivateCloud"
  #Classless Inter-Domain Routing 
  #IPv4 addresses for the vpc
  cidr = "192.168.0.0/16"

  #availability zones
  azs = ["eu-west-2a", "eu-west-2b"] //, "eu-west-2c"]

  #SUBNETS - range of ip addresses in the vpc - subset of CIDR

  private_subnets = ["192.168.1.0/24", "192.168.2.0/24", "192.168.3.0/24"]

  #to route to an internet gateway
  #needs public ipv4 or elastic ip 
  public_subnets = ["192.168.100.0/24"] //, "10.0.102.0/24", "10.0.103.0/24"]

  #traffic routed to a vpn gateway for a site-to-site vpn connection
  #enables access to your remote network from your VPC by creating an AWS Site-to-Site VPN (Site-to-Site VPN) connection, 
  #and configuring routing to pass traffic through the connection. 
  enable_vpn_gateway = true
  
  #enables internet access from the  inside 
  enable_nat_gateway = true

}

############################################  EC2 INSTANCE ##################################################
resource "aws_instance" "myEC2" {
  ami = "ami-0194c3e07668a7e36" # UBUNTU - ssh user is "ubuntu"
  #LINUX2 AMI's user is ec2-user
  instance_type               = "t2.micro"
  subnet_id                   = module.vpc.public_subnets[0]
  key_name                    = "personal_key"
  associate_public_ip_address = true
  vpc_security_group_ids      = [aws_security_group.ec2-sg.id]

  //passing user data to the instance 
  //that can be used to perform common automated 
  //configuration tasks and even run scripts after the instance starts. 
  user_data = <<-EOF
                #!/bin/bash
                sudo apt-get update
                sudo apt-get install -y mysql-client
              EOF
  #-y argument overrides the y/n question of apt-get
}
 
#################################### AWS SSH KEY ######################################################

resource "aws_key_pair" "generated_key" {
  key_name   = "personal_key"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCwU8n52OUIiSk0P6XPkh/We3C7ClVBVOadrBCISm9c6NA3iGBdCwGuuyviKlGa0IvjebnE9OZMZ5AVG6wUbnmDyxQAIU2FXF6D2Pxb2Efp0/6FEw/B2TrIUiro2xO3DZTPMduQeFVCqTfWuoTNbzy4llOC5B4s0IGIBYDjMtxxmIS8eF5C0V6VdGx4l9UrlC2ZV4RVSZTMRuzBVrPpwubXaLgKYhWefvU7y0IVO3zFJq1inOaw3pmVklUlZ6ugCxFL+UJ+loIiIX/kgm03hbcPqyAt+JBjgCiofBqu75xDezz4YFiax1JKRTdE655D7i8ZAkHK9ep8l7A/NnuVL2oxSBVOXphmmcN06g8gnbcep8kOAaeMB9qR0RF8SSK5y43mSCJPFxHme97CiPz7BKMa8atEI+XcYJvucFK0xQ199qs0j+rspypL+NNsWS/vMtznHmFpVtjRShzqjsIpfbf+R9QXo5G0nfaCF3QeSnqi/zvav527rLWg5mAaIN/Qr7U= r@r-XPS-15-9570"
  #public key must be consumed from ENV var - bash profile file to load variables
}


############################################  EC2 SECURITY GROUP ##################################################
resource "aws_security_group" "ec2-sg" {
  name        = "security_group"
  description = "allow outside access to EC2"
  vpc_id      = module.vpc.vpc_id

  #traffic to enter 
  #protocol = -1 -> all protocols

  ingress {
    protocol    = "tcp"
    from_port   = 22
    to_port     = 22
    description = "allow ssh connections to my ec2"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
/*   #HTTP
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    description = "HTTP"
    cidr_blocks = ["0.0.0.0/0"]
  }
  #HTTPS
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    description = "HTTPS"
    cidr_blocks = ["0.0.0.0/0"]
  } */

  #traffic to exit
  egress {
    protocol    = -1 #all protocols
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
}

############################################### ELASTIC IP  ###############################################################
#public fixed IP - not required

/* resource "aws_eip" "eip-ec2" {
  instance = "${aws_instance.myEC2.id}"
  vpc = true
  tags = {
    Name = "ec2 elastic ip"module.vpc.public_subnets[0] , module.vpc.public_subnets[1]]
  }
} */


############################################# OUTPUTS ##################################################
# to get EC2 public ip and  and RDS endpoint

output "rds_endpoint" {
  value = aws_db_instance.myDB.endpoint #only accessible from VPC
} 

output "ec2_public_ip" {
  value = aws_instance.myEC2.public_ip

} 
