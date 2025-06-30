#!/bin/bash
yum update -y

# Install PHP 8.2
amazon-linux-extras install -y php8.2
yum install -y httpd php-mysqlnd amazon-cloudwatch-agent amazon-ssm-agent

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
            "file_path": "/var/log/httpd/access_log",
            "log_group_name": "lamp-stack-app-access",
            "log_stream_name": "{instance_id}"
          },
          {
            "file_path": "/var/log/httpd/error_log",
            "log_group_name": "lamp-stack-app-error",
            "log_stream_name": "{instance_id}"
          }
        ]
      }
    }
  },
  "metrics": {
    "namespace": "LAMP/AppTier",
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

# Create visitor save endpoint
cat > /var/www/html/save_visitor.php << 'EOF'
<?php
header('Content-Type: application/json');

$db_host = "${db_private_ip}"; // Database server IP
$db_user = "appuser";
$db_pass = "${db_password}";
$db_name = "lampdb";

try {
    $pdo = new PDO("mysql:host=$db_host;dbname=$db_name", $db_user, $db_pass);
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
    
    $input = json_decode(file_get_contents('php://input'), true);
    
    $stmt = $pdo->prepare("INSERT INTO visitors (ip_address, country, city, browser, os, user_agent) VALUES (?, ?, ?, ?, ?, ?)");
    $stmt->execute([
        $input['ip'],
        $input['country'],
        $input['city'],
        $input['browser'],
        $input['os'],
        $input['user_agent']
    ]);
    
    echo json_encode(['status' => 'success', 'message' => 'Visitor saved']);
} catch (Exception $e) {
    echo json_encode(['status' => 'error', 'message' => $e->getMessage()]);
}
?>
EOF

# Create visitor retrieval endpoint
cat > /var/www/html/get_visitors.php << 'EOF'
<?php
header('Content-Type: application/json');

$db_host = "${db_private_ip}"; // Database server IP
$db_user = "appuser";
$db_pass = "${db_password}";
$db_name = "lampdb";

try {
    $pdo = new PDO("mysql:host=$db_host;dbname=$db_name", $db_user, $db_pass);
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
    
    $stmt = $pdo->query("SELECT * FROM visitors ORDER BY visit_time DESC LIMIT 10");
    $visitors = $stmt->fetchAll(PDO::FETCH_ASSOC);
    
    echo json_encode(['status' => 'success', 'visitors' => $visitors]);
} catch (Exception $e) {
    echo json_encode(['status' => 'error', 'message' => $e->getMessage()]);
}
?>
EOF

systemctl start httpd
systemctl enable httpd
systemctl start amazon-cloudwatch-agent
systemctl enable amazon-cloudwatch-agent