# Required Variables
variable "do_token" {
  description = "DigitalOcean API token"
  type        = string
  sensitive   = true
}

variable "ssh_key_name" {
  description = "Name of the SSH key in DigitalOcean"
  type        = string
}

variable "external_database_url" {
  description = "External database connection string"
  type        = string
  sensitive   = true
}

# Project Configuration
variable "project_name" {
  description = "Name of the project (used for resource naming)"
  type        = string
  default     = "portfolio"
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "prod"
}

variable "region" {
  description = "DigitalOcean region"
  type        = string
  default     = "sgp1"
}

# Droplet Configuration
variable "droplet_size" {
  description = "Size of the application droplet"
  type        = string
  default     = "s-1vcpu-1gb"
  
  validation {
    condition = contains([
      "s-1vcpu-1gb", "s-1vcpu-2gb", "s-2vcpu-2gb", 
      "s-2vcpu-4gb", "s-4vcpu-8gb", "s-6vcpu-16gb"
    ], var.droplet_size)
    error_message = "Droplet size must be a valid DigitalOcean size slug."
  }
}

# Database Configuration - Using external database

# Application Configuration
variable "app_port" {
  description = "Port the application runs on"
  type        = string
  default     = "8080"
}

# Security Configuration
variable "allowed_ssh_ips" {
  description = "List of IP addresses allowed to SSH to the droplet"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

# Domain Configuration (Optional)
variable "domain_name" {
  description = "Domain name for SSL certificate (leave empty to skip SSL setup)"
  type        = string
  default     = ""
}

# Container Registry Configuration
variable "registry_subscription_tier" {
  description = "Container registry subscription tier"
  type        = string
  default     = "starter"  # Free tier with 500MB storage
  
  validation {
    condition = contains([
      "starter", "basic", "professional"
    ], var.registry_subscription_tier)
    error_message = "Registry subscription tier must be starter, basic, or professional."
  }
}