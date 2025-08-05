# DigitalOcean Terraform Deployment

This directory contains Terraform configuration to deploy the Portfolio Backend application to DigitalOcean

## Architecture

The deployment creates:

- **VPC**: Isolated network for all resources
- **Droplet**: Ubuntu 20.04 server running Docker + Nginx
- **Container Registry**: Private Docker registry for application images
- **Firewall**: Security rules for the application
- **SSL Certificate**: Let's Encrypt certificate via Certbot (optional, if domain provided)
- **External Database**: Uses your existing Neon PostgreSQL database (managed by Vercel)

## Prerequisites

1. **DigitalOcean Account**: Create an account at [digitalocean.com](https://digitalocean.com)

2. **DigitalOcean API Token**:

   - Go to API section in DigitalOcean control panel
   - Generate a new personal access token
   - Keep it secure - you'll need it for Terraform

3. **SSH Key**:

   - Upload your SSH public key to DigitalOcean
   - Note the name you give it (you'll need this for Terraform)

4. **Tools**:

   ```bash
   # Install Terraform
   # Windows (using Chocolatey)
   choco install terraform

   # macOS (using Homebrew)
   brew install terraform

   # Install doctl (DigitalOcean CLI)
   # Windows
   choco install doctl

   # macOS
   brew install doctl
   ```

5. **Domain Name** (Optional):
   - If you want SSL/HTTPS, you'll need a domain name
   - Point your domain's DNS to DigitalOcean nameservers

## Quick Start

1. **Configure Variables**:

   ```bash
   cp terraform.tfvars.example terraform.tfvars
   # Edit terraform.tfvars with your values
   ```

2. **Initialize Terraform**:

   ```bash
   cd terraform
   terraform init
   ```

3. **Plan Deployment**:

   ```bash
   terraform plan
   ```

4. **Deploy Infrastructure**:

   ```bash
   terraform apply
   ```

5. **Deploy Application**:
   ```bash
   # From project root
   ./scripts/deploy.sh
   ```

## Configuration

### Required Variables

Edit `terraform.tfvars`:

```hcl
# DigitalOcean API token
do_token = "your-digitalocean-api-token-here"

# SSH key name (as it appears in DigitalOcean)
ssh_key_name = "your-ssh-key-name"

# Your existing external database connection string
external_database_url = "postgres://admin:password@localhost:5432/portfolio?sslmode=disable"
```

### Ultra Minimal Configuration (Defaults)

```hcl
# Project settings
project_name = "portfolio"
environment = "prod"
region = "sgp1"

droplet_size = "s-1vcpu-1gb"
registry_subscription_tier = "starter"

# Security
allowed_ssh_ips = ["your.ip.address.here/32"]  # Replace with your IP

# Domain for SSL (optional)
# domain_name = "api.yourdomain.com"
```

## Available Regions

Common DigitalOcean regions:

- `nyc1`, `nyc3` - New York
- `sfo3` - San Francisco
- `tor1` - Toronto
- `lon1` - London
- `fra1` - Frankfurt
- `ams3` - Amsterdam
- `sgp1` - Singapore
- `blr1` - Bangalore

## Droplet Sizes

Common sizes for this application:

- `s-1vcpu-1gb` - $6/month (minimum)
- `s-1vcpu-2gb` - $12/month (recommended for production)
- `s-2vcpu-2gb` - $18/month
- `s-2vcpu-4gb` - $24/month

## Container Registry Tiers

- `starter` - $0/month (500MB storage, 500MB bandwidth) ⭐ **Ultra Minimal**
- `basic` - $5/month (5GB storage, 5GB bandwidth)
- `professional` - $20/month (100GB storage, 100GB bandwidth)

## Deployment Process

### 1. Infrastructure Deployment

```bash
cd terraform
terraform init
terraform plan
terraform apply
```

This creates all the infrastructure but doesn't deploy your application yet.

### 2. Application Deployment

```bash
# From project root
./scripts/deploy.sh
```

This script:

1. Builds your Docker image
2. Pushes it to the DigitalOcean Container Registry
3. Deploys it to your server
4. Runs database migrations
5. Performs health checks

### 3. Manual Deployment (Alternative)

If you prefer manual deployment:

```bash
# 1. Build and tag image
docker build -t portfolio-backend .

# 2. Authenticate with registry
doctl registry login

# 3. Get registry endpoint
REGISTRY=$(terraform output -raw container_registry_endpoint)

# 4. Tag and push
docker tag portfolio-backend $REGISTRY/portfolio-backend:latest
docker push $REGISTRY/portfolio-backend:latest

# 5. SSH to server and deploy
SERVER_IP=$(terraform output -raw droplet_ip)
ssh ubuntu@$SERVER_IP
cd /opt/portfolio
./deploy.sh
```

## Accessing Your Application

After deployment:

```bash
# Get application URL
terraform output application_url

# Get droplet IP
terraform output droplet_ip

# Check application health
curl http://$(terraform output -raw droplet_ip)/health
```

## SSL/HTTPS Setup

To enable HTTPS:

1. Set `domain_name` in `terraform.tfvars`
2. Point your domain's DNS to the droplet IP
3. Run `terraform apply` again

The system will automatically:

- Request a Let's Encrypt certificate via Certbot
- Configure HTTPS on Nginx
- Redirect HTTP to HTTPS

## Monitoring and Logs

### Application Logs

```bash
# SSH to server
ssh ubuntu@$(terraform output -raw droplet_ip)

# View application logs
cd /opt/portfolio
docker-compose logs -f
```

### System Logs

```bash
# Service status
sudo systemctl status portfolio

# System logs
journalctl -u portfolio -f
```

### Health Checks

```bash
# Manual health check
curl http://$(terraform output -raw droplet_ip)/health

# Or on server
ssh ubuntu@$(terraform output -raw droplet_ip)
cd /opt/portfolio && ./health-check.sh
```

## Scaling

### Vertical Scaling (Bigger Server)

1. Update `droplet_size` in `terraform.tfvars`
2. Run `terraform apply`
3. The server will be resized (brief downtime)

### Container Registry Scaling

1. Update `registry_subscription_tier` in `terraform.tfvars` (starter → basic → professional)
2. Run `terraform apply`
3. Registry will be upgraded immediately

### Horizontal Scaling (Multiple Servers)

This configuration supports one server. For multiple servers:

1. Convert droplet to a managed Kubernetes cluster, or
2. Use DigitalOcean App Platform instead

## Backup and Recovery

### Database Backups

- Neon database handles automatic backups
- Point-in-time recovery available in Neon dashboard
- No additional cost for backups

### Application Backups

- Container images are stored in the registry
- Application data should be stateless
- Database contains all persistent data
- Droplet snapshots available for $1.20/month (optional)

## Security

### Firewall Rules

- SSH access only from specified IPs
- HTTP/HTTPS ports (80/443) open to public
- Application port (8080) restricted to SSH IPs only
- Database connection secured via SSL to external Neon database

### SSL/TLS

- Database connections use SSL
- HTTPS enforced when domain is configured
- Let's Encrypt certificates auto-renew

### Updates

```bash
# SSH to server
ssh ubuntu@$(terraform output -raw droplet_ip)

# Update system packages
sudo apt update && sudo apt upgrade -y

# Update Docker images
cd /opt/portfolio
./deploy.sh
```

## Troubleshooting

### Common Issues

1. **"SSH key not found"**

   - Verify SSH key name in DigitalOcean matches `ssh_key_name`

2. **"Database connection failed"**

   - Verify Neon database URL is correct in `terraform.tfvars`
   - Check if Neon database is active in dashboard
   - Ensure SSL mode is configured properly

3. **"Application not accessible"**

   - Check health endpoint: `curl http://DROPLET_IP/health`
   - Verify nginx is running: `sudo systemctl status nginx`
   - Check application logs: `docker-compose logs`

4. **"SSL certificate failed"**
   - Ensure domain DNS points to droplet IP (not load balancer)
   - Wait up to 10 minutes for certificate provisioning
   - Check certbot logs: `sudo journalctl -u certbot`

### Getting Help

```bash
# Check Terraform state
terraform show

# View all outputs
terraform output

# Check server status
ssh ubuntu@$(terraform output -raw droplet_ip) 'sudo systemctl status portfolio'

# View application logs
ssh ubuntu@$(terraform output -raw droplet_ip) 'cd /opt/portfolio && docker-compose logs'
```

## Cleanup

To destroy all resources:

```bash
terraform destroy
```

**Warning**: This will permanently delete all data including the database!

## Cost Estimation

**🎯 Ultra Minimal Setup (Default Configuration):**

- Droplet (s-1vcpu-1gb): $6/month
- Neon Database (Vercel): $0/month (free tier)
- Container Registry (starter): $0/month (free tier)
- **Total**: **$6/month** 🚀

**Alternative Personal Setup:**

- Droplet (s-1vcpu-2gb): $12/month
- Neon Database (Vercel): $0/month (free tier)
- Container Registry (basic): $5/month
- **Total**: ~$17/month

**Cost Savings vs Full Production Setup:**

- Removed Load Balancer: -$12/month
- Using external Neon database: -$15/month
- Using Nginx + Certbot instead of managed SSL
- Direct droplet access with firewall protection
- **Total Savings**: $27/month (61% reduction!)

**Comparison:**

- Full Production (DO): $44/month
- Optimized Personal: $17/month
- Ultra Minimal: $6/month

Costs may vary based on:

- Data transfer (first 1TB free)
- Droplet storage usage
- Container registry usage
- Neon database limits (free tier has usage caps)

## Next Steps

1. Set up monitoring with DigitalOcean Monitoring
2. Configure log aggregation
3. Set up CI/CD pipeline
4. Add staging environment
5. Implement blue-green deployments
