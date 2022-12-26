# tạo ssh keypair cho ec2 instance, https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/key_pair
resource "aws_key_pair" "ssh_key_pair" {
  key_name = "${var.prefix}-ssh"
  public_key = var.public_ssh_key
}

# https://registry.terraform.io/modules/terraform-aws-modules/security-group/aws/4.9.0
module "ec2_security_group" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "4.9.0"

  name        = "${var.prefix}-web-security-group-${var.env}"
  description = "Security group for Web ec2 instances"
  vpc_id      = module.vpc.vpc_id

  ingress_cidr_blocks = ["0.0.0.0/0"]
  ingress_rules       = ["http-80-tcp", "all-icmp", "ssh-tcp"]
  egress_rules        = ["all-all"]
}

## EC2 https://registry.terraform.io/modules/terraform-aws-modules/ec2-instance/aws

# Homework 1
# tạo ec2 instances ở public subnet, zone-a
module "public_ec2_za" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "~> 3.0"

  name = "${var.prefix}-${var.env}-public-web-za"

  ami                    = "ami-005835d578c62050d"
  instance_type          = "t2.micro"
  key_name               = aws_key_pair.ssh_key_pair.key_name
  vpc_security_group_ids = [module.ec2_security_group.security_group_id]
  subnet_id              = element(module.vpc.public_subnets, 0)

  user_data = <<-EOT
  Content-Type: multipart/mixed; boundary="//"
  MIME-Version: 1.0

  --//
  Content-Type: text/cloud-config; charset="us-ascii"
  MIME-Version: 1.0
  Content-Transfer-Encoding: 7bit
  Content-Disposition: attachment; filename="cloud-config.txt"

  #cloud-config
  cloud_final_modules:
  - [scripts-user, always]

  --//
  Content-Type: text/x-shellscript; charset="us-ascii"
  MIME-Version: 1.0
  Content-Transfer-Encoding: 7bit
  Content-Disposition: attachment; filename="userdata.txt"

  #!/bin/bash
  sudo su
  echo 'Your name:<b>Pham Hoang Anh</b><br>' > index.html
  echo 'Host name:<b> ' $HOSTNAME  '</b><br>' >> index.html
  echo 'Instance id:<b> ' `wget -q -O - http://169.254.169.254/latest/meta-data/instance-id` '</b><br>' >> index.html
  echo 'Availability zone: <b>' `wget -q -O - http://169.254.169.254/latest/meta-data/placement/availability-zone` '</b><br>' >> index.html
  echo 'Instance type: <b>' `wget -q -O - http://169.254.169.254/latest/meta-data/instance-type` '</b><br>' >> index.html
  python3 -m http.server 80
  EOT

  tags = {
    Terraform   = "true"
    Environment = var.env
  }
}

# Homework 2
# tạo ec2 instances ở public subnet, zone-b
module "public_ec2_zb" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "~> 3.0"

  name = "${var.prefix}-${var.env}-public-web-zb"

  ami                    = "ami-005835d578c62050d"
  instance_type          = "t2.micro"
  key_name               = aws_key_pair.ssh_key_pair.key_name
  vpc_security_group_ids = [module.ec2_security_group.security_group_id]
  subnet_id              = element(module.vpc.public_subnets, 1)

  user_data = <<-EOT
  #!/bin/bash
  sudo su
  yum update -y
  yum install git -y
  amazon-linux-extras install nginx1
  cd /usr/share/nginx
  git clone https://github.com/iwanttobebetterr/techmaster-aws-lab.git
  systemctl enable nginx.service
  systemctl start nginx.service
  EOT

  tags = {
    Terraform   = "true"
    Environment = var.env
  }
}

# tạo ec2 instances ở private subnet, zone-a
module "private_ec2_za" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "~> 3.0"

  name = "${var.prefix}-${var.env}-private-web-zb"

  ami                    = "ami-005835d578c62050d"
  instance_type          = "t2.micro"
  key_name               = aws_key_pair.ssh_key_pair.key_name
  vpc_security_group_ids = [module.ec2_security_group.security_group_id]
  subnet_id              = element(module.vpc.private_subnets, 0)

  tags = {
    Terraform   = "true"
    Environment = var.env
  }
}

output "ec2_za_public_id" {
  description = "The ID of the public instance za"
  value       = module.public_ec2_za.id
}

output "ec2_zb_public_id" {
  description = "The ID of the public instance zb"
  value       = module.public_ec2_zb.id
}

output "ec2_private_id" {
  description = "The ID of the private instance"
  value       = module.private_ec2_za.id
}