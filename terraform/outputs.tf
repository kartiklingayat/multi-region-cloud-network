output "app_latency_url" {
  value = "http://app.${var.domain_name}"
}
output "failover_url" {
  value = "http://failover.${var.domain_name}"
}
output "primary_alb_dns" {
  value = module.primary.alb_dns_name
}
output "secondary_alb_dns" {
  value = module.secondary.alb_dns_name
}
