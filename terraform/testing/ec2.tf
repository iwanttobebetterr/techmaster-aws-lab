# tạo ssh keypair cho ec2 instance, https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/key_pair
resource "aws_key_pair" "ssh_key_pair" {
  key_name = "${var.prefix}-ssh"

  # replace the below with your public key
  public_key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINOLYKFpjL2umZV7YYJ+OMCUBVksoUWO79wFcGDzxtSs anhph.dev@gmail.com"
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

output "ec2_public_id" {
  description = "The ID of the public instance"
  value       = module.public_ec2_za.id
}

output "ec2_private_id" {
  description = "The ID of the private instance"
  value       = module.private_ec2_za.id
}