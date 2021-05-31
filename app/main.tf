# infrastructure-modules/app/main.tf
provider "aws" {
  region = "eu-central-1"
  # ... other provider settings ...
}
terraform {
  backend "s3" {
    bucket  = "my-terraform-state8904jgj4f84944-terragrunt2"
    //encrypt = true
    key     = "app/terraform.tfstate"
    region  = "eu-central-1"
  }
}

data "aws_ami" "latest_ubuntu" {
  owners      = ["099720109477"]
  most_recent = true
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-bionic-18.04-amd64-server-*"]
  }
}

data "aws_availability_zones" "working" {}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "2.21.0"

  name = var.vpc_name
  cidr = var.vpc_cidr

  //azs             = var.vpc_azs
  azs = data.aws_availability_zones.working.names
  private_subnets = var.vpc_private_subnets
  public_subnets  = var.vpc_public_subnets

  enable_nat_gateway = var.vpc_enable_nat_gateway

  tags = var.vpc_tags
}

module "ec2_instances" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "2.12.0"

  name           = var.instance_name
  instance_count = 2

  //ami                    = "ami-0c5204531f799e0c6"
  ami                    = data.aws_ami.latest_ubuntu.id
  instance_type          = var.instance_type 
  vpc_security_group_ids = [module.vpc.default_security_group_id]
  subnet_id              = module.vpc.public_subnets[0]

  tags = {
    Terraform   = "true"
    Environment = "dev"
  }
}