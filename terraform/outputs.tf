output "droplet_ip" {
  description = "Public IP address of the application droplet"
  value       = digitalocean_droplet.app.ipv4_address
}

output "droplet_private_ip" {
  description = "Private IP address of the application droplet"
  value       = digitalocean_droplet.app.ipv4_address_private
}

output "container_registry_endpoint" {
  description = "Container registry endpoint"
  value       = digitalocean_container_registry.portfolio.endpoint
}

output "container_registry_server_url" {
  description = "Container registry server URL"
  value       = digitalocean_container_registry.portfolio.server_url
}

output "vpc_id" {
  description = "VPC ID"
  value       = digitalocean_vpc.portfolio.id
}

output "application_url" {
  description = "Application URL (direct to droplet)"
  value       = var.domain_name != "" ? "https://${var.domain_name}" : "http://${digitalocean_droplet.app.ipv4_address}"
}