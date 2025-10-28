#!/bin/bash

# ==============================|| FLOWISE VPS DEPLOYMENT SCRIPT ||============================== #
# This script deploys Flowise with custom "AI Assistant" branding on a VPS
# Author: AI Assistant
# Version: 1.0

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
DOMAIN=""
EMAIL=""
FLOWISE_PASSWORD=""
DB_PASSWORD=""

echo -e "${BLUE}🚀 FLOWISE VPS DEPLOYMENT WITH AI ASSISTANT BRANDING${NC}"
echo -e "${BLUE}===================================================${NC}"

# Function to print colored output
print_status() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

# Check if running as root
if [[ $EUID -eq 0 ]]; then
   print_error "This script should not be run as root for security reasons"
   exit 1
fi

# Get user input
echo -e "${YELLOW}📝 Configuration Setup${NC}"
read -p "Enter your domain name (or IP address): " DOMAIN
read -p "Enter your email for SSL certificates: " EMAIL
read -s -p "Enter password for Flowise admin: " FLOWISE_PASSWORD
echo
read -s -p "Enter password for database: " DB_PASSWORD
echo

print_info "Domain: $DOMAIN"
print_info "Email: $EMAIL"

# Update system
print_info "Updating system packages..."
sudo apt update && sudo apt upgrade -y

# Install required packages
print_info "Installing required packages..."
sudo apt install -y curl wget git nginx certbot python3-certbot-nginx ufw

# Install Docker
print_info "Installing Docker..."
if ! command -v docker &> /dev/null; then
    curl -fsSL https://get.docker.com -o get-docker.sh
    sudo sh get-docker.sh
    sudo usermod -aG docker $USER
    rm get-docker.sh
    print_status "Docker installed successfully"
else
    print_status "Docker already installed"
fi

# Install Docker Compose
print_info "Installing Docker Compose..."
if ! command -v docker-compose &> /dev/null; then
    sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose
    print_status "Docker Compose installed successfully"
else
    print_status "Docker Compose already installed"
fi

# Create project directory
PROJECT_DIR="/opt/flowise-ai-assistant"
print_info "Creating project directory: $PROJECT_DIR"
sudo mkdir -p $PROJECT_DIR
sudo chown $USER:$USER $PROJECT_DIR

# Copy project files
print_info "Copying project files..."
cp -r . $PROJECT_DIR/
cd $PROJECT_DIR

# Create Docker Compose file for VPS
cat > docker-compose-vps.yml << EOF
version: '3.8'

services:
  flowise:
    build:
      context: .
      dockerfile: Dockerfile.vps
    container_name: flowise-ai-assistant
    restart: unless-stopped
    ports:
      - "3000:3000"
    environment:
      - NODE_ENV=production
      - PORT=3000
      - FLOWISE_USERNAME=admin
      - FLOWISE_PASSWORD=$FLOWISE_PASSWORD
      - FLOWISE_SECRETKEY=$(openssl rand -hex 32)
      - DATABASE_URL=postgresql://flowise:$DB_PASSWORD@postgres:5432/flowise
      - CREDENTIAL_ENCRYPTION_KEY=$(openssl rand -hex 32)
      - API_KEY_ENCRYPTION_KEY=$(openssl rand -hex 32)
      - JWT_SECRET=$(openssl rand -hex 32)
    depends_on:
      - postgres
    volumes:
      - flowise_data:/root/.flowise
    networks:
      - flowise-network

  postgres:
    image: postgres:15-alpine
    container_name: flowise-postgres
    restart: unless-stopped
    environment:
      - POSTGRES_DB=flowise
      - POSTGRES_USER=flowise
      - POSTGRES_PASSWORD=$DB_PASSWORD
    volumes:
      - postgres_data:/var/lib/postgresql/data
    networks:
      - flowise-network

  nginx:
    image: nginx:alpine
    container_name: flowise-nginx
    restart: unless-stopped
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./nginx-vps.conf:/etc/nginx/nginx.conf:ro
      - /etc/letsencrypt:/etc/letsencrypt:ro
    depends_on:
      - flowise
    networks:
      - flowise-network

volumes:
  flowise_data:
  postgres_data:

networks:
  flowise-network:
    driver: bridge
EOF

# Create Dockerfile for VPS
cat > Dockerfile.vps << EOF
FROM node:18-alpine

WORKDIR /app

# Install pnpm
RUN npm install -g pnpm

# Copy package files
COPY package.json pnpm-lock.yaml pnpm-workspace.yaml ./
COPY packages/ ./packages/

# Install dependencies
RUN pnpm install --frozen-lockfile

# Build the application
RUN pnpm build

# Expose port
EXPOSE 3000

# Start the application
CMD ["pnpm", "start"]
EOF

# Create Nginx configuration
cat > nginx-vps.conf << EOF
events {
    worker_connections 1024;
}

http {
    upstream flowise {
        server flowise:3000;
    }

    # Rate limiting
    limit_req_zone \$binary_remote_addr zone=api:10m rate=10r/s;
    limit_req_zone \$binary_remote_addr zone=login:10m rate=5r/m;

    server {
        listen 80;
        server_name $DOMAIN;
        
        # Redirect HTTP to HTTPS
        return 301 https://\$server_name\$request_uri;
    }

    server {
        listen 443 ssl http2;
        server_name $DOMAIN;

        # SSL Configuration
        ssl_certificate /etc/letsencrypt/live/$DOMAIN/fullchain.pem;
        ssl_certificate_key /etc/letsencrypt/live/$DOMAIN/privkey.pem;
        ssl_protocols TLSv1.2 TLSv1.3;
        ssl_ciphers ECDHE-RSA-AES256-GCM-SHA512:DHE-RSA-AES256-GCM-SHA512:ECDHE-RSA-AES256-GCM-SHA384:DHE-RSA-AES256-GCM-SHA384;
        ssl_prefer_server_ciphers off;
        ssl_session_cache shared:SSL:10m;
        ssl_session_timeout 10m;

        # Security headers
        add_header X-Frame-Options DENY;
        add_header X-Content-Type-Options nosniff;
        add_header X-XSS-Protection "1; mode=block";
        add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;

        # Rate limiting
        limit_req zone=api burst=20 nodelay;
        limit_req zone=login burst=5 nodelay;

        # Proxy to Flowise
        location / {
            proxy_pass http://flowise;
            proxy_http_version 1.1;
            proxy_set_header Upgrade \$http_upgrade;
            proxy_set_header Connection 'upgrade';
            proxy_set_header Host \$host;
            proxy_set_header X-Real-IP \$remote_addr;
            proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto \$scheme;
            proxy_cache_bypass \$http_upgrade;
            proxy_read_timeout 300s;
            proxy_connect_timeout 75s;
        }

        # Health check
        location /health {
            access_log off;
            return 200 "healthy\n";
            add_header Content-Type text/plain;
        }
    }
}
EOF

# Configure firewall
print_info "Configuring firewall..."
sudo ufw --force enable
sudo ufw allow ssh
sudo ufw allow 80
sudo ufw allow 443

# Get SSL certificate
print_info "Obtaining SSL certificate..."
sudo certbot certonly --nginx -d $DOMAIN --email $EMAIL --agree-tos --non-interactive

# Start services
print_info "Starting Flowise services..."
docker-compose -f docker-compose-vps.yml up -d

# Wait for services to start
print_info "Waiting for services to start..."
sleep 30

# Check if services are running
if docker-compose -f docker-compose-vps.yml ps | grep -q "Up"; then
    print_status "Flowise is running successfully!"
    print_status "Access your AI Assistant at: https://$DOMAIN"
    print_status "Admin username: admin"
    print_status "Admin password: $FLOWISE_PASSWORD"
else
    print_error "Failed to start services. Check logs with: docker-compose -f docker-compose-vps.yml logs"
    exit 1
fi

# Create maintenance script
cat > vps-maintenance.sh << EOF
#!/bin/bash

case "\$1" in
    start)
        echo "Starting Flowise..."
        docker-compose -f docker-compose-vps.yml up -d
        ;;
    stop)
        echo "Stopping Flowise..."
        docker-compose -f docker-compose-vps.yml down
        ;;
    restart)
        echo "Restarting Flowise..."
        docker-compose -f docker-compose-vps.yml restart
        ;;
    logs)
        docker-compose -f docker-compose-vps.yml logs -f
        ;;
    update)
        echo "Updating Flowise..."
        git pull
        docker-compose -f docker-compose-vps.yml build --no-cache
        docker-compose -f docker-compose-vps.yml up -d
        ;;
    backup)
        echo "Creating backup..."
        docker-compose -f docker-compose-vps.yml exec postgres pg_dump -U flowise flowise > backup_\$(date +%Y%m%d_%H%M%S).sql
        ;;
    *)
        echo "Usage: \$0 {start|stop|restart|logs|update|backup}"
        exit 1
        ;;
esac
EOF

chmod +x vps-maintenance.sh

print_status "Deployment completed successfully!"
print_info "Your AI Assistant is now running at: https://$DOMAIN"
print_info "Use './vps-maintenance.sh' for maintenance operations"

echo -e "${GREEN}"
echo "🎉 DEPLOYMENT SUCCESSFUL! 🎉"
echo "=========================="
echo "🌐 URL: https://$DOMAIN"
echo "👤 Username: admin"
echo "🔑 Password: $FLOWISE_PASSWORD"
echo "🛠️  Maintenance: ./vps-maintenance.sh"
echo "📊 Logs: docker-compose -f docker-compose-vps.yml logs -f"
echo -e "${NC}"
