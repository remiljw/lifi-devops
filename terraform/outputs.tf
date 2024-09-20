output "load_balancer_dns" {
  description = "DNS name of the ALB"
  value       = aws_lb.nlb.dns_name
}
