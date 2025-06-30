variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "web_instance_id" {
  description = "Web tier instance ID"
  type        = string
}

variable "app_instance_id" {
  description = "App tier instance ID"
  type        = string
}

variable "db_instance_id" {
  description = "DB tier instance ID"
  type        = string
}