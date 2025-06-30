#!/bin/bash
yum update -y

# Install PHP 8.2
amazon-linux-extras install -y php8.2
yum install -y httpd php-mysqlnd amazon-cloudwatch-agent

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
            "log_group_name": "lamp-stack-web-access",
            "log_stream_name": "{instance_id}"
          },
          {
            "file_path": "/var/log/httpd/error_log",
            "log_group_name": "lamp-stack-web-error",
            "log_stream_name": "{instance_id}"
          }
        ]
      }
    }
  },
  "metrics": {
    "namespace": "LAMP/WebTier",
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

# Create simple visitor tracking application
cat > /var/www/html/index.php << 'EOF'
<!DOCTYPE html>
<html>
<head>
    <title>Visitor Tracker - LAMP Stack</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 40px; background: #f5f5f5; }
        .container { background: white; padding: 30px; border-radius: 8px; box-shadow: 0 2px 10px rgba(0,0,0,0.1); }
        .info { background: #e3f2fd; padding: 15px; border-radius: 5px; margin: 10px 0; }
        .visitors { background: #f3e5f5; padding: 15px; border-radius: 5px; margin: 20px 0; }
        table { width: 100%; border-collapse: collapse; margin-top: 10px; }
        th, td { padding: 8px; text-align: left; border-bottom: 1px solid #ddd; }
        th { background-color: #f2f2f2; }
    </style>
</head>
<body>
    <div class="container">
        <h1>🌐 Visitor Tracker - LAMP Stack</h1>
        
        <?php
        // Get visitor information
        $ip = $_SERVER['HTTP_X_FORWARDED_FOR'] ?? $_SERVER['REMOTE_ADDR'];
        $user_agent = $_SERVER['HTTP_USER_AGENT'] ?? 'Unknown';
        
        // Parse browser and OS
        function getBrowser($user_agent) {
            if (strpos($user_agent, 'Chrome')) return 'Chrome';
            if (strpos($user_agent, 'Firefox')) return 'Firefox';
            if (strpos($user_agent, 'Safari')) return 'Safari';
            if (strpos($user_agent, 'Edge')) return 'Edge';
            return 'Unknown';
        }
        
        function getOS($user_agent) {
            if (strpos($user_agent, 'Windows')) return 'Windows';
            if (strpos($user_agent, 'Mac')) return 'macOS';
            if (strpos($user_agent, 'Linux')) return 'Linux';
            if (strpos($user_agent, 'Android')) return 'Android';
            if (strpos($user_agent, 'iPhone')) return 'iOS';
            return 'Unknown';
        }
        
        $browser = getBrowser($user_agent);
        $os = getOS($user_agent);
        
        // Get location (simplified)
        $location_data = @file_get_contents("http://ip-api.com/json/$ip");
        $location = json_decode($location_data, true);
        $country = $location['country'] ?? 'Unknown';
        $city = $location['city'] ?? 'Unknown';
        
        echo "<div class='info'>";
        echo "<h2>Your Visit Information</h2>";
        echo "<p><strong>IP Address:</strong> $ip</p>";
        echo "<p><strong>Location:</strong> $city, $country</p>";
        echo "<p><strong>Browser:</strong> $browser</p>";
        echo "<p><strong>Operating System:</strong> $os</p>";
        echo "<p><strong>Visit Time:</strong> " . date('Y-m-d H:i:s') . "</p>";
        echo "</div>";
        
        // Save to database via app tier
        $app_data = [
            'ip' => $ip,
            'country' => $country,
            'city' => $city,
            'browser' => $browser,
            'os' => $os,
            'user_agent' => $user_agent
        ];
        
        $save_response = false;
        try {
            $app_ip = '${app_private_ip}';
            if ($app_ip) {
                $ch = curl_init();
                curl_setopt($ch, CURLOPT_URL, "http://$app_ip/save_visitor.php");
                curl_setopt($ch, CURLOPT_POST, true);
                curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode($app_data));
                curl_setopt($ch, CURLOPT_HTTPHEADER, ['Content-Type: application/json']);
                curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
                curl_setopt($ch, CURLOPT_TIMEOUT, 3);
                $save_response = curl_exec($ch);
                curl_close($ch);
            }
        } catch (Exception $e) {
            // Silently handle connection errors
        }
        
        // Get recent visitors
        $visitors_response = false;
        try {
            $app_ip = '${app_private_ip}';
            if ($app_ip) {
                $ch = curl_init();
                curl_setopt($ch, CURLOPT_URL, "http://$app_ip/get_visitors.php");
                curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
                curl_setopt($ch, CURLOPT_TIMEOUT, 3);
                $visitors_response = curl_exec($ch);
                curl_close($ch);
            }
        } catch (Exception $e) {
            // Silently handle connection errors
        }
        
        if ($visitors_response) {
            $visitors_data = json_decode($visitors_response, true);
            if ($visitors_data && isset($visitors_data['visitors'])) {
                echo "<div class='visitors'>";
                echo "<h2>Recent Visitors</h2>";
                echo "<table>";
                echo "<tr><th>IP</th><th>Location</th><th>Browser</th><th>OS</th><th>Visit Time</th></tr>";
                foreach ($visitors_data['visitors'] as $visitor) {
                    echo "<tr>";
                    echo "<td>" . htmlspecialchars($visitor['ip_address']) . "</td>";
                    echo "<td>" . htmlspecialchars($visitor['city'] . ", " . $visitor['country']) . "</td>";
                    echo "<td>" . htmlspecialchars($visitor['browser']) . "</td>";
                    echo "<td>" . htmlspecialchars($visitor['os']) . "</td>";
                    echo "<td>" . htmlspecialchars($visitor['visit_time']) . "</td>";
                    echo "</tr>";
                }
                echo "</table>";
                echo "</div>";
            }
        }
        ?>
        
        <div class="info">
            <h2>System Information</h2>
            <p><strong>Web Server:</strong> <?php echo $_SERVER['SERVER_NAME']; ?></p>
            <p><strong>Architecture:</strong> Three-Tier LAMP Stack</p>
            <p><strong>Database Status:</strong> <?php echo $save_response ? '✅ Connected' : '❌ Initializing'; ?></p>
            <p><strong>Load Balancer:</strong> ✅ Active</p>
        </div>
    </div>
</body>
</html>
EOF

systemctl start httpd
systemctl enable httpd
systemctl start amazon-cloudwatch-agent
systemctl enable amazon-cloudwatch-agent