#                    __ _
#    ___ ___  _ __  / _(_) __ _
#   / __/ _ \| '_ \| |_| |/ _` |
#  | (_| (_) | | | |  _| | (_| |
#   \___\___/|_| |_|_| |_|\__, |
#                         |___/

terraform {
  backend "s3" {
    bucket         = "commercial-bingo-app-terraform-backend"
    key            = "state/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "commercial-bingo-app-terraform-backend-lock"
    encrypt        = true
    profile        = "chiellini-dev"
  }

  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }

  required_version = ">= 0.14.9"
}

provider "aws" {
  region = var.region
  profile = "chiellini-dev"
}

#                       _       _
#   _ __ ___   ___   __| |_   _| | ___  ___
#  | '_ ` _ \ / _ \ / _` | | | | |/ _ \/ __|
#  | | | | | | (_) | (_| | |_| | |  __/\__ \
#  |_| |_| |_|\___/ \__,_|\__,_|_|\___||___/

module "terraform_backend" {
  source = "../../modules/terraform_backend"
  app    = var.terraform_backend_name
}

module "networking" {
  source                      = "../../modules/networking"
  org                         = var.org
  app                         = var.app
  vpc_id                      = var.vpc_id
  igw_id                      = var.igw_id
  private_subnet_range        = var.private_subnet_range
  public_subnet_range         = var.public_subnet_range
  cidr_block                  = var.cidr_block
}

module "bastion" {
  source      = "../../modules/bastion"
  environment = var.environment
  app         = var.app
  vpc_id      = module.networking.vpc_id
  subnets     = module.networking.private_subnets
}

module "lambda" {
  source      = "../../modules/lambda"
  environment = var.environment
  app         = var.app
  vpc_id      = module.networking.vpc_id
}

module "rds" {
  source          = "../../modules/rds"
  environment     = var.environment
  app             = var.app
  db_name         = var.db_name
  vpc_id          = module.networking.vpc_id
  cidr_blocks     = module.networking.cidr_blocks
  vpc_cidr_block  = var.cidr_block
  private_subnets = module.networking.private_subnets
  bastion_sg      = module.bastion.bastion_sg
  lambda_sg       = module.lambda.lambda_sg
}

module "route53" {
  source      = "../../modules/route53"
  domain      = var.domain
  environment = var.environment
}

module "ui" {
  source        = "../../modules/ui"
  environment   = var.environment
  app           = var.app
  domain        = var.frontend_domain
  certificate   = module.route53.cert
  whitelist_ips = var.whitelist_ips
  zone_id       = module.route53.zone_id
}

module "api" {
  source                    = "../../modules/api"
  domain                    = var.backend_domain
  certificate               = module.route53.cert
  zone_id                   = module.route53.zone_id
  environment               = var.environment
  app                       = var.app
  lambda_sg                 = module.lambda.lambda_sg
  private_subnets           = module.networking.private_subnets
  db_proxy_endpoint         = module.rds.db_proxy_endpoint
  db_username               = module.rds.db_username
  db_password               = module.rds.db_password
  db_port                   = module.rds.db_port
  db_name                   = module.rds.db_name
  whitelist_ips             = var.whitelist_ips
}
