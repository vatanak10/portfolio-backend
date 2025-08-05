terraform {
  required_version = ">= 1.0"
  required_providers {
    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = "~> 2.0"
    }
  }
}

provider "digitalocean" {
  token = var.do_token
}

# Data sources
data "digitalocean_ssh_key" "main" {
  name = var.ssh_key_name
}

# Container Registry
resource "digitalocean_container_registry" "portfolio" {
  name                   = "${var.project_name}-registry"
  subscription_tier_slug = var.registry_subscription_tier
  region                 = var.region
}

# VPC for network isolation
resource "digitalocean_vpc" "portfolio" {
  name     = "${var.project_name}-vpc"
  region   = var.region
  ip_range = "10.10.0.0/16"
}

# Application Droplet
resource "digitalocean_droplet" "app" {
  image    = "docker-20-04"
  name     = "${var.project_name}-app"
  region   = var.region
  size     = var.droplet_size
  vpc_uuid = digitalocean_vpc.portfolio.id

  ssh_keys = [data.digitalocean_ssh_key.main.id]

  user_data = templatefile("${path.module}/cloud-init.yml", {
    registry_endpoint = digitalocean_container_registry.portfolio.endpoint
    db_connection_string = var.external_database_url
    app_port         = var.app_port
    environment      = var.environment
    domain_name      = var.domain_name
  })

  tags = [var.environment, "app"]

  depends_on = [
    digitalocean_container_registry.portfolio
  ]
}

# Firewall Rules
resource "digitalocean_firewall" "app_firewall" {
  name = "${var.project_name}-app-firewall"

  droplet_ids = [digitalocean_droplet.app.id]

  # SSH access
  inbound_rule {
    protocol         = "tcp"
    port_range       = "22"
    source_addresses = var.allowed_ssh_ips
  }

  # HTTP access (port 80)
  inbound_rule {
    protocol         = "tcp"
    port_range       = "80"
    source_addresses = ["0.0.0.0/0"]
  }

  # HTTPS access (port 443)
  inbound_rule {
    protocol         = "tcp"
    port_range       = "443"
    source_addresses = ["0.0.0.0/0"]
  }

  # Application port (for direct access during development)
  inbound_rule {
    protocol         = "tcp"
    port_range       = var.app_port
    source_addresses = var.allowed_ssh_ips
  }

  # Allow all outbound traffic
  outbound_rule {
    protocol              = "tcp"
    port_range            = "1-65535"
    destination_addresses = ["0.0.0.0/0", "::/0"]
  }

  outbound_rule {
    protocol              = "udp"
    port_range            = "1-65535"
    destination_addresses = ["0.0.0.0/0", "::/0"]
  }

  outbound_rule {
    protocol              = "icmp"
    destination_addresses = ["0.0.0.0/0", "::/0"]
  }

  tags = [var.environment, "firewall"]
}