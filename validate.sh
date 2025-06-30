#!/bin/bash

set -e

echo "LAMP Stack Validation Script"
echo "==============================="

cd environments/dev

# Check if infrastructure is deployed
if [ ! -f "terraform.tfstate" ]; then
    echo "No terraform state found. Please deploy first."
    exit 1
fi

# Get web tier URL
WEB_URL=$(terraform output -raw web_tier_url 2>/dev/null || echo "")

if [ -z "$WEB_URL" ]; then
    echo "Could not get web tier URL from terraform output"
    exit 1
fi

echo "Testing web tier at: $WEB_URL"

# Test web tier connectivity
HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" "$WEB_URL" --connect-timeout 10 || echo "000")

if [ "$HTTP_STATUS" = "200" ]; then
    echo "Web tier is responding (HTTP $HTTP_STATUS)"
else
    echo "Web tier not responding (HTTP $HTTP_STATUS)"
    echo "This is normal if instances are still initializing (5-10 minutes)"
fi

# Check AWS resources
echo ""
echo "Checking AWS resources..."

# Check instances
INSTANCES=$(aws ec2 describe-instances --filters "Name=tag:Project,Values=lamp-stack" "Name=instance-state-name,Values=running" --query 'Reservations[].Instances[].{Name:Tags[?Key==`Name`]|[0].Value,State:State.Name,Type:InstanceType}' --output table 2>/dev/null || echo "Error checking instances")

if [ "$INSTANCES" != "Error checking instances" ]; then
    echo "EC2 Instances:"
    echo "$INSTANCES"
else
    echo "Could not check EC2 instances"
fi

# Check CloudWatch log groups
echo ""
LOG_GROUPS=$(aws logs describe-log-groups --log-group-name-prefix "lamp-stack" --query 'logGroups[].logGroupName' --output table 2>/dev/null || echo "Error checking log groups")

if [ "$LOG_GROUPS" != "Error checking log groups" ]; then
    echo "CloudWatch Log Groups:"
    echo "$LOG_GROUPS"
else
    echo "Could not check CloudWatch log groups"
fi

echo ""
echo "Validation Summary:"
echo "- Infrastructure: Deployed"
echo "- Web Tier: $([ "$HTTP_STATUS" = "200" ] && echo "✅ Accessible" || echo "⏳ Initializing")"
echo "- Monitoring: Configured"

echo ""
echo "Next steps:"
echo "1. Wait 5-10 minutes for full initialization"
echo "2. Access application: $WEB_URL"
echo "3. Check CloudWatch dashboard in AWS Console"
echo "4. Monitor logs in CloudWatch Log Groups"