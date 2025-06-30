#!/bin/bash

KEY_NAME="lamp-stack-key"
REGION="eu-west-1"

echo "Creating AWS Key Pair: $KEY_NAME"

# Create key pair and save private key
aws ec2 create-key-pair \
    --key-name "$KEY_NAME" \
    --region "$REGION" \
    --query 'KeyMaterial' \
    --output text > "$KEY_NAME.pem"

# Settin proper permissions
chmod 400 "$KEY_NAME.pem"

echo "Key pair created successfully!"
echo "Private key saved as: $KEY_NAME.pem"
echo "Permissions set to 400"

echo ""
echo "Now you can run: ./deploy.sh"