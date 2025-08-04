output "alb_dns_name" {
  description = "Public DNS of ALB to access Strapi app"
  value       = aws_lb.alb.dns_name
}
