#!/bin/bash

cd environments/dev

# Test database connection from app tier
APP_ID=$(aws ec2 describe-instances --filters "Name=tag:Name,Values=lamp-stack-app-dev" --query 'Reservations[0].Instances[0].InstanceId' --output text --region eu-west-1)

echo "Testing DB connection from app tier..."

aws ssm send-command \
    --instance-ids "$APP_ID" \
    --document-name "AWS-RunShellScript" \
    --parameters 'commands=[
        "php -r \"try { \\$pdo = new PDO(\\\"mysql:host=lamp-stack-db-dev;dbname=lampdb\\\", \\\"appuser\\\", \\\"PenguinoPassword123!\\\"); echo \\\"✅ DB Connected\\\"; } catch(Exception \\$e) { echo \\\"❌ DB Error: \\\" . \\$e->getMessage(); }\""
    ]' \
    --region eu-west-1

echo "Check command output in AWS Console SSM"