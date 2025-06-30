output "alb_sg_id" {
  description = "Security Group ID for ALB"
  value       = aws_security_group.alb.id
}

output "web_sg_id" {
  description = "Security Group ID for Web Tier"
  value       = aws_security_group.web.id
}

output "app_sg_id" {
  description = "Security Group ID for App Tier"
  value       = aws_security_group.app.id
}

output "db_sg_id" {
  description = "Security Group ID for DB Tier"
  value       = aws_security_group.db.id
}