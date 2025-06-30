#!/bin/bash

echo "Checking database initialization..."

cd environments/dev

# Get DB instance ID
DB_INSTANCE_ID=$(terraform output -json | jq -r '.web_tier_public_ip.value' | xargs -I {} aws ec2 describe-instances --filters "Name=tag:Name,Values=lamp-stack-db-dev" --query 'Reservations[0].Instances[0].InstanceId' --output text --region eu-west-1)

if [ "$DB_INSTANCE_ID" = "None" ] || [ -z "$DB_INSTANCE_ID" ]; then
    echo "Could not find DB instance"
    exit 1
fi

echo "DB Instance: $DB_INSTANCE_ID"

# Check if MySQL is running
echo "Checking MySQL service..."
aws ssm send-command \
    --instance-ids "$DB_INSTANCE_ID" \
    --document-name "AWS-RunShellScript" \
    --parameters 'commands=["sudo systemctl status mysqld","sudo mysql -u root -pPenguinoPassword123! -e \"SHOW DATABASES;\""]' \
    --region eu-west-1 \
    --output table

echo "Wait 30 seconds then check command results in AWS Console"
echo "Or test the application again: $(terraform output -raw web_tier_url)"