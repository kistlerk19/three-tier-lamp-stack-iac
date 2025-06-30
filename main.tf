module "vpc" {
  source = "./modules/vpc"
  
  vpc_cidr         = var.vpc_cidr
  project_name     = var.project_name
  environment      = var.environment
  availability_zones = data.aws_availability_zones.available.names
}

module "security_groups" {
  source = "./modules/security_group"
  
  vpc_id       = module.vpc.vpc_id
  project_name = var.project_name
  environment  = var.environment
}

module "alb" {
  source = "./modules/alb"
  
  vpc_id            = module.vpc.vpc_id
  subnet_ids        = module.vpc.public_subnet_ids
  security_group_id = module.security_groups.alb_sg_id
  project_name      = var.project_name
  environment       = var.environment
}

module "web_tier" {
  source = "./modules/ec2"
  
  instance_type     = var.instance_type
  key_name         = var.key_pair_name
  subnet_id        = module.vpc.public_subnet_ids[0]
  security_group_ids = [module.security_groups.web_sg_id]
  user_data        = templatefile("${path.module}/modules/ec2/user_data_web.sh", {
    app_private_ip = module.app_tier.private_ip
  })
  instance_name    = "${var.project_name}-web-${var.environment}"
  tier            = "web"
}

resource "aws_lb_target_group_attachment" "web" {
  target_group_arn = module.alb.target_group_arn
  target_id        = module.web_tier.instance_id
  port             = 80
}

module "app_tier" {
  source = "./modules/ec2"
  
  instance_type     = var.instance_type
  key_name         = var.key_pair_name
  subnet_id        = module.vpc.private_subnet_ids[0]
  security_group_ids = [module.security_groups.app_sg_id]
  user_data        = templatefile("${path.module}/modules/ec2/user_data_app.sh", {
    db_password = var.db_password
    db_private_ip = module.db_tier.private_ip
  })
  instance_name    = "${var.project_name}-app-${var.environment}"
  tier            = "app"
}

module "db_tier" {
  source = "./modules/ec2"
  
  instance_type     = var.instance_type
  key_name         = var.key_pair_name
  subnet_id        = module.vpc.private_subnet_ids[1]
  security_group_ids = [module.security_groups.db_sg_id]
  user_data        = templatefile("${path.module}/modules/ec2/user_data_db.sh", {
    db_password = var.db_password
  })
  instance_name    = "${var.project_name}-db-${var.environment}"
  tier            = "db"
}

module "monitoring" {
  source = "./modules/monitoring"
  
  project_name = var.project_name
  environment  = var.environment
  web_instance_id = module.web_tier.instance_id
  app_instance_id = module.app_tier.instance_id
  db_instance_id  = module.db_tier.instance_id
}

data "aws_availability_zones" "available" {
  state = "available"
}