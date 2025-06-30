resource "aws_cloudwatch_log_group" "web_access" {
  name              = "lamp-stack-web-access"
  retention_in_days = 7
}

resource "aws_cloudwatch_log_group" "web_error" {
  name              = "lamp-stack-web-error"
  retention_in_days = 7
}

resource "aws_cloudwatch_log_group" "app_access" {
  name              = "lamp-stack-app-access"
  retention_in_days = 7
}

resource "aws_cloudwatch_log_group" "app_error" {
  name              = "lamp-stack-app-error"
  retention_in_days = 7
}

resource "aws_cloudwatch_log_group" "db_mysql" {
  name              = "lamp-stack-db-mysql"
  retention_in_days = 7
}

resource "aws_cloudwatch_metric_alarm" "high_cpu_web" {
  alarm_name          = "${var.project_name}-web-high-cpu-${var.environment}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "300"
  statistic           = "Average"
  threshold           = "80"
  alarm_description   = "This metric monitors web tier cpu utilization"

  dimensions = {
    InstanceId = var.web_instance_id
  }
}

resource "aws_cloudwatch_metric_alarm" "high_cpu_app" {
  alarm_name          = "${var.project_name}-app-high-cpu-${var.environment}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "300"
  statistic           = "Average"
  threshold           = "80"
  alarm_description   = "This metric monitors app tier cpu utilization"

  dimensions = {
    InstanceId = var.app_instance_id
  }
}

resource "aws_cloudwatch_metric_alarm" "high_cpu_db" {
  alarm_name          = "${var.project_name}-db-high-cpu-${var.environment}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "300"
  statistic           = "Average"
  threshold           = "80"
  alarm_description   = "This metric monitors db tier cpu utilization"

  dimensions = {
    InstanceId = var.db_instance_id
  }
}

resource "aws_cloudwatch_dashboard" "lamp_stack" {
  dashboard_name = "${var.project_name}-dashboard-${var.environment}"

  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 12
        height = 6

        properties = {
          metrics = [
            ["AWS/EC2", "CPUUtilization", "InstanceId", var.web_instance_id],
            [".", ".", ".", var.app_instance_id],
            [".", ".", ".", var.db_instance_id]
          ]
          view    = "timeSeries"
          stacked = false
          region  = "eu-west-1"
          title   = "EC2 Instance CPU Utilization"
          period  = 300
        }
      }
    ]
  })
}