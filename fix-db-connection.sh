#!/bin/bash

echo "Fixing database connection..."

cd environments/dev

# Get instance IDs
DB_ID=$(aws ec2 describe-instances --filters "Name=tag:Name,Values=lamp-stack-db-dev" "Name=instance-state-name,Values=running" --query 'Reservations[0].Instances[0].InstanceId' --output text --region eu-west-1)
APP_ID=$(aws ec2 describe-instances --filters "Name=tag:Name,Values=lamp-stack-app-dev" "Name=instance-state-name,Values=running" --query 'Reservations[0].Instances[0].InstanceId' --output text --region eu-west-1)

if [ "$DB_ID" = "None" ] || [ -z "$DB_ID" ]; then
    echo "Database instance not found"
    exit 1
fi

echo "Database Instance: $DB_ID"
echo "App Instance: $APP_ID"

# Connect to database instance and fix MySQL
echo "🔧 Restarting MySQL and fixing configuration..."

# Create the fix script
cat > /tmp/fix-mysql.sh << 'EOF'
#!/bin/bash
echo "Starting MySQL fix at $(date)"

# Stop MySQL
sudo systemctl stop mysqld

# Remove any lock files
sudo rm -f /var/lib/mysql/mysql.sock.lock
sudo rm -f /var/run/mysqld/mysqld.pid

# Start MySQL
sudo systemctl start mysqld
sleep 10

# Check if MySQL is running
if sudo systemctl is-active --quiet mysqld; then
    echo "MySQL is running"
    
    # Test database connection
    mysql -u root -p'PenguinoPassword123!' -e "SHOW DATABASES;" 2>/dev/null
    if [ $? -eq 0 ]; then
        echo "Root connection works"
        
        # Recreate database and user
        mysql -u root -p'PenguinoPassword123!' << 'EOSQL'
DROP DATABASE IF EXISTS lampdb;
CREATE DATABASE lampdb;
DROP USER IF EXISTS 'appuser'@'%';
CREATE USER 'appuser'@'%' IDENTIFIED BY 'PenguinoPassword123!';
GRANT ALL PRIVILEGES ON lampdb.* TO 'appuser'@'%';
FLUSH PRIVILEGES;

USE lampdb;
CREATE TABLE visitors (
    id INT AUTO_INCREMENT PRIMARY KEY,
    ip_address VARCHAR(45),
    country VARCHAR(100),
    city VARCHAR(100),
    browser VARCHAR(100),
    os VARCHAR(100),
    user_agent TEXT,
    visit_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

INSERT INTO visitors (ip_address, country, city, browser, os, user_agent) 
VALUES ('127.0.0.1', 'Test', 'Test', 'Test', 'Test', 'Database is working!');
EOSQL
        
        echo "Database and tables created"
    else
        echo "Root connection failed"
    fi
else
    echo "MySQL failed to start"
fi

echo "MySQL fix completed at $(date)"
EOF

# Copy and execute the fix script on the database server
aws ssm send-command \
    --instance-ids "$DB_ID" \
    --document-name "AWS-RunShellScript" \
    --parameters "commands=[\"$(cat /tmp/fix-mysql.sh | sed 's/"/\\"/g')\"]" \
    --region eu-west-1 \
    --output table

echo "Database fix initiated. Wait 60 seconds then test the application."
echo "Test URL: $(terraform output -raw web_tier_url)"

# Clean up
rm -f /tmp/fix-mysql.sh