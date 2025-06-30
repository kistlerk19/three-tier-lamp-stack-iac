output "log_group_name" {
  description = "CloudWatch log group name"
  value       = aws_cloudwatch_log_group.web_access.name
}

output "dashboard_url" {
  description = "CloudWatch dashboard URL"
  value       = "https://console.aws.amazon.com/cloudwatch/home?region=eu-west-1#dashboards:name=${aws_cloudwatch_dashboard.lamp_stack.dashboard_name}"
}