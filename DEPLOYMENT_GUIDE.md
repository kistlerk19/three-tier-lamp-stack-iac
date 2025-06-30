# LAMP Stack Deployment Guide

## Quick Deployment

### 1. Prerequisites Setup
```bash
# Ensure AWS CLI is configured
aws configure

# Verify Terraform installation
terraform --version
```

### 2. Configuration
```bash
# Copy example configuration
cp terraform.tfvars.example environments/dev/terraform.tfvars

# Edit configuration
nano environments/dev/terraform.tfvars
```

**Required Changes:**
- `key_pair_name`: Your AWS key pair name
- `db_password`: Secure database password

### 3. Deploy Infrastructure
```bash
# Option 1: Automated deployment
./deploy.sh

# Option 2: Manual deployment
cd environments/dev
terraform init
terraform plan
terraform apply
```

### 4. Validate Deployment
```bash
# Run validation checks
./validate.sh

# Test the visitor tracking application
./test_app.sh
```

## Architecture Overview

```
Internet Gateway
       |
   Public Subnet (Web Tier)
   [Apache + PHP + CloudWatch]
       |
   Private Subnet (App Tier)
   [PHP Logic + CloudWatch]
       |
   Private Subnet (DB Tier)
   [MySQL + CloudWatch]
```

## Cost Breakdown (Monthly)

| Component | Cost (USD) |
|-----------|------------|
| 3x t3.micro instances | ~$15 |
| NAT Gateway | ~$32 |
| EBS Storage (24GB) | ~$2.40 |
| CloudWatch | ~$5 |
| **Total** | **~$55** |

## Key Features

### Modular Design
- **VPC Module**: Network infrastructure
- **Security Groups**: Tiered access control
- **EC2 Module**: Reusable compute instances
- **Monitoring Module**: CloudWatch integration

### Cost Optimization
- Single NAT Gateway (vs. per-AZ)
- t3.micro instances (Free Tier eligible)
- gp3 EBS volumes (better price/performance)
- 7-day log retention

### Security
- Network segmentation (public/private subnets)
- Security groups with least privilege
- Encrypted EBS volumes
- IAM roles for CloudWatch access

### Monitoring & Logging
- **Log Groups**: Access/error logs for each tier
- **Metrics**: CPU, memory, disk utilization
- **Alarms**: 80% CPU threshold alerts
- **Dashboard**: Centralized monitoring

## Validation Checklist

After deployment, verify:

- [ ] Web tier accessible via public IP
- [ ] Application returns JSON from app tier
- [ ] Database connectivity working
- [ ] CloudWatch logs appearing
- [ ] Metrics being collected
- [ ] Alarms configured

## Troubleshooting

### Common Issues

**1. Key Pair Not Found**
```bash
# List available key pairs
aws ec2 describe-key-pairs --query 'KeyPairs[].KeyName'
```

**2. Instance Launch Failures**
- Check security group rules
- Verify subnet configuration
- Ensure IAM permissions

**3. Application Not Responding**
- Wait 5-10 minutes for initialization
- Check CloudWatch logs for errors
- Verify security group HTTP access

**4. Database Connection Issues**
- Check MySQL service status
- Verify security group port 3306
- Confirm password configuration

### Log Locations

**CloudWatch Log Groups:**
- `lamp-stack-web-access`: Apache access logs
- `lamp-stack-web-error`: Apache error logs
- `lamp-stack-app-access`: App tier access logs
- `lamp-stack-app-error`: App tier error logs
- `lamp-stack-db-mysql`: MySQL logs

## Cleanup

```bash
cd environments/dev
terraform destroy
```

## Scaling Considerations

### Immediate Improvements
- Add Application Load Balancer
- Implement Auto Scaling Groups
- Use RDS instead of EC2 MySQL
- Add SSL/TLS certificates

### Production Readiness
- Multi-AZ deployment
- Database backups
- Log aggregation (ELK stack)
- Infrastructure monitoring (Datadog/New Relic)
- CI/CD pipeline integration

## Security Enhancements

### Network Security
- VPC Flow Logs
- AWS WAF integration
- Network ACLs

### Application Security
- Secrets Manager for passwords
- Parameter Store for configuration
- AWS Systems Manager for patching

### Monitoring Security
- CloudTrail for API logging
- GuardDuty for threat detection
- Config for compliance monitoring