#!/bin/bash
exec > >(tee /var/log/user-data.log) 2>&1
echo "Starting DB initialization at $(date)"

yum update -y
yum install -y mysql-server amazon-cloudwatch-agent amazon-ssm-agent

# Start SSM agent
systemctl start amazon-ssm-agent
systemctl enable amazon-ssm-agent

# Install CloudWatch agent
wget https://s3.amazonaws.com/amazoncloudwatch-agent/amazon_linux/amd64/latest/amazon-cloudwatch-agent.rpm
rpm -U ./amazon-cloudwatch-agent.rpm

# Configure CloudWatch agent
cat > /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json << 'EOF'
{
  "logs": {
    "logs_collected": {
      "files": {
        "collect_list": [
          {
            "file_path": "/var/log/mysqld.log",
            "log_group_name": "lamp-stack-db-mysql",
            "log_stream_name": "{instance_id}"
          }
        ]
      }
    }
  },
  "metrics": {
    "namespace": "LAMP/DBTier",
    "metrics_collected": {
      "cpu": {
        "measurement": ["cpu_usage_idle", "cpu_usage_iowait", "cpu_usage_user", "cpu_usage_system"],
        "metrics_collection_interval": 60
      },
      "disk": {
        "measurement": ["used_percent"],
        "metrics_collection_interval": 60,
        "resources": ["*"]
      },
      "mem": {
        "measurement": ["mem_used_percent"],
        "metrics_collection_interval": 60
      }
    }
  }
}
EOF

# Start CloudWatch agent
/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -a fetch-config -m ec2 -c file:/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json -s

# Configure MySQL
echo "Starting MySQL service..."
systemctl start mysqld
systemctl enable mysqld

# Wait for MySQL to fully start
echo "Waiting for MySQL to initialize..."
sleep 60

# Get temporary password
echo "Getting temporary password..."
TEMP_PASS=$(grep 'temporary password' /var/log/mysqld.log | awk '{print $NF}')
echo "Temp password found: $TEMP_PASS"

# Set root password and create database
if [ -z "$TEMP_PASS" ]; then
    echo "No temp password found, setting password directly..."
    mysqladmin -u root password '${db_password}'
else
    echo "Using temp password to set new password..."
    mysql -u root -p"$TEMP_PASS" --connect-expired-password -e "ALTER USER 'root'@'localhost' IDENTIFIED BY '${db_password}';"
fi

# Configure MySQL to accept connections from any host
echo "bind-address = 0.0.0.0" >> /etc/my.cnf
systemctl restart mysqld
sleep 10

# Create database and user
mysql -u root -p'${db_password}' << EOF
CREATE DATABASE IF NOT EXISTS lampdb;
CREATE USER IF NOT EXISTS 'appuser'@'%' IDENTIFIED BY '${db_password}';
GRANT ALL PRIVILEGES ON lampdb.* TO 'appuser'@'%';
FLUSH PRIVILEGES;

USE lampdb;
CREATE TABLE IF NOT EXISTS visitors (
    id INT AUTO_INCREMENT PRIMARY KEY,
    ip_address VARCHAR(45),
    country VARCHAR(100),
    city VARCHAR(100),
    browser VARCHAR(100),
    os VARCHAR(100),
    user_agent TEXT,
    visit_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS test_table (
    id INT AUTO_INCREMENT PRIMARY KEY,
    message VARCHAR(255),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

INSERT IGNORE INTO test_table (message) VALUES ('Database tier is working!');
INSERT IGNORE INTO visitors (ip_address, country, city, browser, os, user_agent) VALUES ('127.0.0.1', 'Test', 'Test', 'Test', 'Test', 'Initial test data');
EOF

echo "Database initialization completed at $(date)"

systemctl start amazon-cloudwatch-agent
systemctl enable amazon-cloudwatch-agent