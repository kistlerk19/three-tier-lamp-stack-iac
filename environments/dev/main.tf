terraform {
  backend "local" {
    path = "terraform.tfstate"
  }
}

module "lamp_stack" {
  source = "../../"
  
  aws_region    = var.aws_region
  project_name  = var.project_name
  environment   = var.environment
  vpc_cidr      = var.vpc_cidr
  instance_type = var.instance_type
  key_pair_name = var.key_pair_name
  db_password   = var.db_password
}

variable "aws_region" {
  description = "AWS region"
  type        = string
}

variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
}

variable "key_pair_name" {
  description = "AWS Key Pair name"
  type        = string
}

variable "db_password" {
  description = "Database password"
  type        = string
  sensitive   = true
}

output "web_tier_url" {
  description = "URL to access the web application"
  value       = module.lamp_stack.web_tier_url
}

output "dashboard_url" {
  description = "CloudWatch dashboard URL"
  value       = "https://console.aws.amazon.com/cloudwatch/home?region=eu-west-1#dashboards:name=${var.project_name}-dashboard-${var.environment}"
}