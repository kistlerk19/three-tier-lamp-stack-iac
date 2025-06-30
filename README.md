# Three-Tier LAMP Stack with Terraform

A modular, cost-effective three-tier LAMP stack infrastructure with comprehensive monitoring and logging.

**Author**: Ishmael Gyamfi

## 🌐 Live Demo

**[View Live Application](http://lamp-stack-alb-dev-795354098.eu-west-1.elb.amazonaws.com/)**

*Experience the three-tier LAMP stack in action with real-time visitor tracking and database integration.*

## Architecture

- **Load Balancer**: Application Load Balancer for high availability
- **Web Tier**: Visitor tracking web application (Apache + PHP 8.2) in public subnet
- **App Tier**: API endpoints for visitor data (PHP 8.2) in private subnet  
- **DB Tier**: MySQL database with visitor tracking table in private subnet
- **Monitoring**: CloudWatch logs, metrics, and alarms
- **Security**: Tiered security groups with least privilege

## Application Features

- **Visitor Tracking**: Captures IP address, geolocation, browser, and OS
- **Real-time Display**: Shows current visitor information
- **Recent Visitors**: Displays last 10 visitors in a table
- **Responsive Design**: Clean, modern web interface
- **Database Integration**: Stores all visitor data in MySQL

## Cost Optimization Features

- t3.micro instances (AWS Free Tier eligible)
- Single NAT Gateway for cost efficiency
- gp3 EBS volumes for better price/performance
- 7-day log retention to minimize storage costs
- Encrypted storage for security

## Prerequisites

1. AWS CLI configured
2. Terraform >= 1.0 installed
3. AWS Key Pair created

## Quick Start

1. **Create AWS Key Pair**:
   ```bash
   ./create-keypair.sh
   ```

2. **Deploy Infrastructure**:
   ```bash
   ./deploy.sh
   ```

3. **Test Application**:
   ```bash
   ./test_app.sh
   ```

4. **Access application**:
   - Web URL will be displayed in outputs
   - CloudWatch dashboard available in AWS Console

## Monitoring & Logging

### CloudWatch Log Groups
- `lamp-stack-web-access`: Apache access logs
- `lamp-stack-web-error`: Apache error logs  
- `lamp-stack-app-access`: App tier access logs
- `lamp-stack-app-error`: App tier error logs
- `lamp-stack-db-mysql`: MySQL logs

### Metrics & Alarms
- CPU utilization monitoring for all tiers
- Automatic alarms at 80% CPU threshold
- Custom metrics for application performance

### Dashboard
- Centralized monitoring dashboard
- Real-time metrics visualization
- Instance health monitoring

## Security Features

- **Network Segmentation**: Public/private subnet isolation
- **Security Groups**: Tiered access control
- **Encryption**: EBS volumes encrypted at rest
- **IAM Roles**: Least privilege access for CloudWatch

## Module Structure

```
├── modules/
│   ├── vpc/           # Network infrastructure
│   ├── alb/           # Application Load Balancer
│   ├── security_group/ # Security controls
│   ├── ec2/           # Compute instances
│   └── monitoring/    # CloudWatch resources
├── environments/
│   └── dev/           # Environment-specific configs
```

## Customization

### Instance Types
Modify `instance_type` in terraform.tfvars:
- `t3.micro` - Free tier eligible
- `t3.small` - Production workloads
- `t3.medium` - Higher performance

### Scaling
- Implement Auto Scaling Groups with ALB
- Implement Auto Scaling Groups
- Use RDS for managed database

## Cleanup

```bash
cd environments/dev
terraform destroy
```

## Cost Estimation

Monthly costs (eu-west-1):
- 3x t3.micro instances: ~$15
- Application Load Balancer: ~$16
- NAT Gateway: ~$32
- EBS storage (24GB): ~$2.4
- CloudWatch logs/metrics: ~$5
- **Total: ~$70/month**

## Troubleshooting

1. **Key Pair Issues**: Ensure key pair exists in target region
2. **Permission Errors**: Verify AWS credentials and IAM permissions
3. **Instance Launch**: Check security group rules and subnet configuration
4. **Application Access**: Verify security groups allow HTTP traffic

## Next Steps

- Implement SSL/TLS certificates
- Add SSL/TLS to Application Load Balancer
- Set up automated backups
- Configure log aggregation
- Implement infrastructure monitoring alerts