variable "region" {
  description = "AWS region"
  default     = "us-east-2" # change as needed
}

variable "ecs_task_execution_role_arn" {
  description = "IAM role ARN for ECS task execution"
  default     = "arn:aws:iam::607700977843:role/ecsTaskExecutionRole-Aryak"
}

variable "strapi_image_tag" {
  description = "ECR image tag for Strapi app"
  default     = "latest"
}

variable "db_username" {
  description = "RDS database username"
  default     = "strapi_user"
}

variable "db_password" {
  description = "RDS database password"
  default     = "strapi123" 
  sensitive   = true
}

variable "db_name" {
  description = "RDS database name"
  default     = "strapi"
}
