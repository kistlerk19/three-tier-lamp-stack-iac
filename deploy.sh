#!/bin/bash

set -e

echo "LAMP Stack Deployment Script"
echo "================================"

# Check prerequisites
command -v terraform >/dev/null 2>&1 || { echo "Terraform is required but not installed."; exit 1; }
command -v aws >/dev/null 2>&1 || { echo "AWS CLI is required but not installed."; exit 1; }

# Check AWS credentials
aws sts get-caller-identity >/dev/null 2>&1 || { echo "AWS credentials not configured."; exit 1; }

echo "Prerequisites check passed"

# Navigate to dev environment
cd environments/dev

# Check if terraform.tfvars exists and has required values
if [ ! -f "terraform.tfvars" ]; then
    echo "terraform.tfvars not found in environments/dev/"
    exit 1
fi

# Check and create key pair if needed
KEY_NAME=$(grep 'key_pair_name' terraform.tfvars | cut -d'=' -f2 | tr -d ' "')

if [ "$KEY_NAME" = "your-key-pair-name" ]; then
    echo "Please update key_pair_name in terraform.tfvars"
    exit 1
fi

# Check if key pair exists
if ! aws ec2 describe-key-pairs --key-names "$KEY_NAME" >/dev/null 2>&1; then
    echo "Key pair '$KEY_NAME' not found. Creating it..."
    aws ec2 create-key-pair --key-name "$KEY_NAME" --query 'KeyMaterial' --output text > "$KEY_NAME.pem"
    chmod 400 "$KEY_NAME.pem"
    echo "Key pair created and saved as $KEY_NAME.pem"
else
    echo "Key pair '$KEY_NAME' exists"
fi

echo "Configuration check passed"

# Initialize Terraform
echo "Initializing Terraform..."
terraform init

# Plan deployment
echo "Planning deployment..."
terraform plan -out=tfplan

# Ask for confirmation
echo ""
read -p "Do you want to proceed with deployment? (y/N): " -n 1 -r
echo ""

if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "Deploying infrastructure..."
    terraform apply tfplan
    
    echo ""
    echo "Deployment completed successfully!"
    echo ""
    echo "Access your application:"
    terraform output web_tier_url
    
    echo ""
    echo "Monitor your infrastructure:"
    echo "- CloudWatch Dashboard: AWS Console > CloudWatch > Dashboards"
    echo "- Log Groups: AWS Console > CloudWatch > Log Groups"
    
    echo ""
    echo "Estimated monthly cost: ~$55 USD"
    echo ""
    echo "To cleanup: terraform destroy"
else
    echo "Deployment cancelled"
    rm -f tfplan
fi