#!/bin/bash

# Portfolio Backend Deployment Script
# This script builds and deploys the application to DigitalOcean

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
PROJECT_NAME="portfolio-backend"
REGISTRY_NAME="portfolio-registry"
IMAGE_TAG=${1:-latest}

# Functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

check_requirements() {
    log_info "Checking requirements..."
    
    # Check if Docker is installed
    if ! command -v docker &> /dev/null; then
        log_error "Docker is not installed. Please install Docker first."
        exit 1
    fi
    
    # Check if Terraform is installed
    if ! command -v terraform &> /dev/null; then
        log_error "Terraform is not installed. Please install Terraform first."
        exit 1
    fi
    
    # Check if doctl is installed
    if ! command -v doctl &> /dev/null; then
        log_warning "doctl is not installed. You'll need it for container registry authentication."
        log_info "Install it from: https://docs.digitalocean.com/reference/doctl/how-to/install/"
    fi
    
    log_success "Requirements check completed"
}

build_image() {
    log_info "Building Docker image..."
    
    # Get git information for build metadata
    VERSION=$(git describe --tags --always --dirty 2>/dev/null || echo "dev")
    COMMIT_SHA=$(git rev-parse HEAD 2>/dev/null || echo "unknown")
    BUILD_DATE=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    
    # Build the Docker image
    docker build \
        --build-arg VERSION="$VERSION" \
        --build-arg COMMIT_SHA="$COMMIT_SHA" \
        --build-arg BUILD_DATE="$BUILD_DATE" \
        -t "$PROJECT_NAME:$IMAGE_TAG" \
        .
    
    log_success "Docker image built successfully"
}

get_registry_info() {
    log_info "Getting container registry information..."
    
    # Get registry endpoint from Terraform output
    REGISTRY_ENDPOINT=$(terraform -chdir=terraform output -raw container_registry_endpoint 2>/dev/null || echo "")
    
    if [ -z "$REGISTRY_ENDPOINT" ]; then
        log_error "Could not get registry endpoint. Make sure Terraform has been applied."
        exit 1
    fi
    
    log_success "Registry endpoint: $REGISTRY_ENDPOINT"
}

authenticate_registry() {
    log_info "Authenticating with DigitalOcean Container Registry..."
    
    # Check if doctl is configured
    if ! doctl auth list &> /dev/null; then
        log_error "doctl is not authenticated. Run 'doctl auth init' first."
        exit 1
    fi
    
    # Authenticate Docker with the registry
    doctl registry login
    
    log_success "Registry authentication completed"
}

push_image() {
    log_info "Pushing image to container registry..."
    
    # Tag image for registry
    docker tag "$PROJECT_NAME:$IMAGE_TAG" "$REGISTRY_ENDPOINT/$PROJECT_NAME:$IMAGE_TAG"
    
    # Push image
    docker push "$REGISTRY_ENDPOINT/$PROJECT_NAME:$IMAGE_TAG"
    
    log_success "Image pushed successfully"
}

deploy_to_server() {
    log_info "Deploying to server..."
    
    # Get droplet IP from Terraform output
    DROPLET_IP=$(terraform -chdir=terraform output -raw droplet_ip 2>/dev/null || echo "")
    
    if [ -z "$DROPLET_IP" ]; then
        log_error "Could not get droplet IP. Make sure Terraform has been applied."
        exit 1
    fi
    
    log_info "Deploying to server: $DROPLET_IP"
    
    # SSH to server and run deployment
    ssh -o StrictHostKeyChecking=no ubuntu@"$DROPLET_IP" << EOF
        cd /opt/portfolio
        ./deploy.sh
EOF
    
    log_success "Deployment completed"
}

run_migrations() {
    log_info "Running database migrations..."
    
    # Get droplet IP
    DROPLET_IP=$(terraform -chdir=terraform output -raw droplet_ip 2>/dev/null || echo "")
    
    if [ -z "$DROPLET_IP" ]; then
        log_error "Could not get droplet IP. Make sure Terraform has been applied."
        exit 1
    fi
    
    # Run migrations on the server using the Neon database connection from .env
    ssh -o StrictHostKeyChecking=no ubuntu@"$DROPLET_IP" << 'EOF'
        # Install Go if not present (needed for goose)
        if ! command -v go &> /dev/null; then
            wget -q https://go.dev/dl/go1.21.5.linux-amd64.tar.gz
            sudo tar -C /usr/local -xzf go1.21.5.linux-amd64.tar.gz
            echo 'export PATH=$PATH:/usr/local/go/bin' >> ~/.bashrc
            export PATH=$PATH:/usr/local/go/bin
        fi
        
        # Install goose if not present
        if ! command -v goose &> /dev/null; then
            go install github.com/pressly/goose/v3/cmd/goose@latest
            export PATH=$PATH:~/go/bin
        fi
        
        # Clone repository and run migrations
        if [ ! -d "/tmp/portfolio-backend" ]; then
            git clone https://github.com/vatanak10/portfolio-backend.git /tmp/portfolio-backend
        else
            cd /tmp/portfolio-backend && git pull
        fi
        
        cd /tmp/portfolio-backend
        
        # Read database connection from the deployed .env file
        source /opt/portfolio/.env
        ~/go/bin/goose -dir cmd/migrate/migrations postgres "$DB_ADDR" up
EOF
    
    log_success "Database migrations completed"
}

health_check() {
    log_info "Performing health check..."
    
    # Get droplet IP
    DROPLET_IP=$(terraform -chdir=terraform output -raw droplet_ip 2>/dev/null || echo "")
    
    if [ -z "$DROPLET_IP" ]; then
        log_error "Could not get droplet IP."
        exit 1
    fi
    
    # Wait for application to be healthy (check both nginx and direct app)
    for i in {1..30}; do
        # Try nginx first (port 80), then direct app port
        if curl -f "http://$DROPLET_IP/health" > /dev/null 2>&1 || curl -f "http://$DROPLET_IP:8080/health" > /dev/null 2>&1; then
            log_success "Application is healthy and accessible at http://$DROPLET_IP"
            return 0
        fi
        log_info "Attempt $i/30: Waiting for application to be ready..."
        sleep 10
    done
    
    log_error "Health check failed. Application may not be running correctly."
    exit 1
}

show_usage() {
    echo "Usage: $0 [IMAGE_TAG]"
    echo ""
    echo "This script builds and deploys the Portfolio Backend application to DigitalOcean."
    echo ""
    echo "Arguments:"
    echo "  IMAGE_TAG    Docker image tag (default: latest)"
    echo ""
    echo "Examples:"
    echo "  $0           # Deploy with 'latest' tag"
    echo "  $0 v1.0.0    # Deploy with 'v1.0.0' tag"
    echo ""
    echo "Prerequisites:"
    echo "  - Docker installed and running"
    echo "  - Terraform installed"
    echo "  - doctl installed and authenticated"
    echo "  - Terraform infrastructure already deployed"
}

main() {
    if [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
        show_usage
        exit 0
    fi
    
    log_info "Starting deployment process..."
    log_info "Image tag: $IMAGE_TAG"
    
    check_requirements
    build_image
    get_registry_info
    authenticate_registry
    push_image
    deploy_to_server
    run_migrations
    health_check
    
    log_success "Deployment completed successfully!"
    log_info "Your application is now running and accessible."
}

# Run main function
main "$@"