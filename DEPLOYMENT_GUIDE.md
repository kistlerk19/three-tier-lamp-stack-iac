# LAMP Stack Deployment Guide

**Author**: Ishmael Gyamfi

## 🌐 Live Demo

**[View Live Application](http://lamp-stack-alb-dev-795354098.eu-west-1.elb.amazonaws.com/)**

*Experience the deployed three-tier LAMP stack with real-time visitor tracking.*

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

# Check database connectivity
./check-db.sh

# Fix database issues if needed
./fix-db-connection.sh
```

## Architecture Overview

### Production Three-Tier Architecture

```
┌─────────────────────────────────────────────────────────────────────────────────┐
│                                  INTERNET                                       │
└─────────────────────────────────┬───────────────────────────────────────────────┘
                                  │
┌─────────────────────────────────────────────────────────────────────────────────┐
│                              AWS VPC (10.0.0.0/16)                             │
│                                                                                 │
│  ┌─────────────────────────────────────────────────────────────────────────┐    │
│  │                        Internet Gateway                                │    │
│  └─────────────────────────────┬───────────────────────────────────────────┘    │
│                                │                                                │
│  ┌─────────────────────────────────────────────────────────────────────────┐    │
│  │              Application Load Balancer (ALB)                           │    │
│  │                    [Health Checks + SSL Ready]                         │    │
│  └─────────────────────────────┬───────────────────────────────────────────┘    │
│                                │                                                │
│  ┌─────────────────────────────────────────────────────────────────────────┐    │
│  │                      PUBLIC SUBNETS                                    │    │
│  │  ┌─────────────────┐                    ┌─────────────────┐             │    │
│  │  │   AZ-1a         │                    │   AZ-1b         │             │    │
│  │  │  Web Tier       │◄──── HTTP ────────►│  Web Tier       │             │    │
│  │  │ Apache + PHP    │                    │ Apache + PHP    │             │    │
│  │  │ CloudWatch      │                    │ CloudWatch      │             │    │
│  │  └─────────┬───────┘                    └─────────┬───────┘             │    │
│  └────────────┼────────────────────────────────────────┼───────────────────┘    │
│               │                                        │                        │
│  ┌────────────┼────────────────────────────────────────┼───────────────────┐    │
│  │            │              PRIVATE SUBNETS           │                   │    │
│  │  ┌─────────▼───────┐                    ┌─────────▼───────┐             │    │
│  │  │   AZ-1a         │                    │   AZ-1b         │             │    │
│  │  │  App Tier       │◄──── API ─────────►│  App Tier       │             │    │
│  │  │ PHP Logic       │                    │ PHP Logic       │             │    │
│  │  │ CloudWatch      │                    │ CloudWatch      │             │    │
│  │  └─────────┬───────┘                    └─────────┬───────┘             │    │
│  │            │                                      │                     │    │
│  │  ┌─────────▼───────┐                    ┌─────────▼───────┐             │    │
│  │  │   AZ-1a         │                    │   AZ-1b         │             │    │
│  │  │  Database       │◄──── MySQL ───────►│  Database       │             │    │
│  │  │ MySQL Server    │                    │ MySQL Server    │             │    │
│  │  │ CloudWatch      │                    │ CloudWatch      │             │    │
│  │  └─────────────────┘                    └─────────────────┘             │    │
│  └─────────────────────────────────────────────────────────────────────────┘    │
│                                                                                 │
│  ┌─────────────────────────────────────────────────────────────────────────┐    │
│  │                         NAT Gateway                                    │    │
│  │                    [Outbound Internet Access]                         │    │
│  └─────────────────────────────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────────────────┐
│                            MONITORING & LOGGING                                │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐                │
│  │  CloudWatch     │  │  CloudWatch     │  │  CloudWatch     │                │
│  │  Logs           │  │  Metrics        │  │  Alarms         │                │
│  │  • Access Logs  │  │  • CPU Usage    │  │  • High CPU     │                │
│  │  • Error Logs   │  │  • Memory       │  │  • Disk Space   │                │
│  │  • MySQL Logs   │  │  • Disk I/O     │  │  • Response     │                │
│  └─────────────────┘  └─────────────────┘  └─────────────────┘                │
└─────────────────────────────────────────────────────────────────────────────────┘
```

### Data Flow Architecture

```
┌─────────────┐    ┌─────────────┐    ┌─────────────┐    ┌─────────────┐
│   VISITOR   │───►│     ALB     │───►│  WEB TIER   │───►│  APP TIER   │
│             │    │             │    │             │    │             │
│ Browser     │    │ • Route 53  │    │ • Apache    │    │ • PHP API   │
│ Mobile App  │    │ • SSL Term  │    │ • PHP UI    │    │ • Business  │
│ API Client  │    │ • Health    │    │ • Static    │    │   Logic     │
└─────────────┘    │   Checks    │    │   Assets    │    │ • Validation│
                   └─────────────┘    └─────────────┘    └─────┬───────┘
                                                               │
┌─────────────────────────────────────────────────────────────▼───────┐
│                        DATABASE TIER                               │
│                                                                     │
│  ┌─────────────┐    ┌─────────────┐    ┌─────────────┐             │
│  │   MySQL     │    │  Visitor    │    │   Session   │             │
│  │  Primary    │───►│   Tracking  │───►│   Storage   │             │
│  │             │    │             │    │             │             │
│  │ • Users     │    │ • IP Geo    │    │ • Cache     │             │
│  │ • Sessions  │    │ • Browser   │    │ • Temp Data │             │
│  │ • Analytics │    │ • Behavior  │    │             │             │
│  └─────────────┘    └─────────────┘    └─────────────┘             │
└─────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────┐
│                    MONITORING DATA FLOW                            │
│                                                                     │
│  All Tiers ────► CloudWatch Logs ────► CloudWatch Metrics          │
│      │                                        │                     │
│      ▼                                        ▼                     │
│  SSM Agent ────► Systems Manager ────► CloudWatch Alarms           │
│      │                                        │                     │
│      ▼                                        ▼                     │
│  IAM Roles ────► Security Audit  ────► CloudWatch Dashboard        │
└─────────────────────────────────────────────────────────────────────┘
```

## Cost Breakdown (Monthly - EU-West-1)

| Component | Cost (USD) | Notes |
|-----------|------------|-------|
| 3x t3.micro instances | ~$15 | Free Tier: 750 hours/month |
| Application Load Balancer | ~$16 | ~$0.0225/hour + LCU charges |
| NAT Gateway | ~$32 | ~$0.045/hour + data transfer |
| EBS Storage (24GB gp3) | ~$2.40 | ~$0.10/GB/month |
| CloudWatch Logs/Metrics | ~$5 | 7-day retention |
| Data Transfer | ~$2 | Minimal inter-AZ transfer |
| **Total** | **~$72** | **Actual production cost** |

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
```bash
# Check database status
./check-db.sh

# Fix database connectivity
./fix-db-connection.sh

# Test direct connection
./test-db-connection.sh
```
- MySQL initialization takes 2-3 minutes
- SSM agent needs time to register
- Check CloudWatch logs for MySQL errors

### Log Locations

**CloudWatch Log Groups:**
- `lamp-stack-web-access`: Apache access logs
- `lamp-stack-web-error`: Apache error logs
- `lamp-stack-app-access`: App tier access logs
- `lamp-stack-app-error`: App tier error logs
- `lamp-stack-db-mysql`: MySQL logs

## Deployment Scripts

### Available Scripts
- `deploy.sh` - Full infrastructure deployment
- `validate.sh` - Post-deployment validation
- `check-db.sh` - Database health check
- `fix-db-connection.sh` - Database connectivity fix
- `test-db-connection.sh` - Database connection test
- `recreate-db-only.sh` - Recreate database instance
- `update-web.sh` - Update web tier only

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