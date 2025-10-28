#!/bin/bash

# FLOWISE VPS DEPLOYMENT SCRIPT
# Complete deployment script for VPS servers

set -e

echo "🚀 FLOWISE VPS DEPLOYMENT"
echo "========================="
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
APP_NAME="flowise"
APP_DIR="/opt/flowise"
SERVICE_USER="flowise"
NGINX_SITES="/etc/nginx/sites-available"
NGINX_ENABLED="/etc/nginx/sites-enabled"
SYSTEMD_SERVICE="/etc/systemd/system"

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    print_error "Please run as root (use sudo)"
    exit 1
fi

print_status "Starting Flowise VPS deployment..."

# Step 1: Update system
print_status "Updating system packages..."
apt update && apt upgrade -y
print_success "System updated"

# Step 2: Install required packages
print_status "Installing required packages..."
apt install -y curl wget git nginx postgresql postgresql-contrib certbot python3-certbot-nginx ufw fail2ban htop
print_success "Required packages installed"

# Step 3: Install Node.js 20
print_status "Installing Node.js 20..."
curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
apt install -y nodejs
print_success "Node.js 20 installed"

# Step 4: Install pnpm
print_status "Installing pnpm..."
npm install -g pnpm
print_success "pnpm installed"

# Step 5: Create application user
print_status "Creating application user..."
if ! id "$SERVICE_USER" &>/dev/null; then
    useradd -r -s /bin/false -d "$APP_DIR" -m "$SERVICE_USER"
    print_success "User $SERVICE_USER created"
else
    print_warning "User $SERVICE_USER already exists"
fi

# Step 6: Create application directory
print_status "Setting up application directory..."
mkdir -p "$APP_DIR"
chown -R "$SERVICE_USER:$SERVICE_USER" "$APP_DIR"
print_success "Application directory created"

# Step 7: Clone repository
print_status "Cloning Flowise repository..."
cd "$APP_DIR"
sudo -u "$SERVICE_USER" git clone https://github.com/ILYESS24/flowisecursor.git .
print_success "Repository cloned"

# Step 8: Install dependencies
print_status "Installing dependencies..."
sudo -u "$SERVICE_USER" pnpm install
print_success "Dependencies installed"

# Step 9: Build application
print_status "Building application..."
sudo -u "$SERVICE_USER" pnpm build
print_success "Application built"

# Step 10: Configure PostgreSQL
print_status "Configuring PostgreSQL..."
sudo -u postgres psql -c "CREATE DATABASE flowise;"
sudo -u postgres psql -c "CREATE USER flowise WITH PASSWORD 'flowise_password';"
sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE flowise TO flowise;"
print_success "PostgreSQL configured"

# Step 11: Create environment file
print_status "Creating environment configuration..."
cat > "$APP_DIR/.env" << EOF
NODE_ENV=production
PORT=3000
DATABASE_URL=postgresql://flowise:flowise_password@localhost:5432/flowise
FLOWISE_USERNAME=admin
FLOWISE_PASSWORD=admin123
FLOWISE_SECRETKEY=your-secret-key-here
APIKEY_PATH=$APP_DIR/.flowise
CORS_ORIGINS=*
ALLOWED_IFRAME_ORIGINS=*
DISABLE_TELEMETRY=true
LOG_LEVEL=info
EOF

chown "$SERVICE_USER:$SERVICE_USER" "$APP_DIR/.env"
chmod 600 "$APP_DIR/.env"
print_success "Environment configuration created"

# Step 12: Create systemd service
print_status "Creating systemd service..."
cat > "$SYSTEMD_SERVICE/flowise.service" << EOF
[Unit]
Description=Flowise AI Application
After=network.target postgresql.service

[Service]
Type=simple
User=$SERVICE_USER
WorkingDirectory=$APP_DIR
ExecStart=/usr/bin/node $APP_DIR/packages/server/bin/render-start.js
Restart=always
RestartSec=10
Environment=NODE_ENV=production
Environment=PORT=3000

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable flowise
print_success "Systemd service created"

# Step 13: Configure Nginx
print_status "Configuring Nginx..."
cat > "$NGINX_SITES/flowise" << EOF
server {
    listen 80;
    server_name your-domain.com www.your-domain.com;

    location / {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_cache_bypass \$http_upgrade;
    }
}
EOF

ln -sf "$NGINX_SITES/flowise" "$NGINX_ENABLED/"
nginx -t && systemctl reload nginx
print_success "Nginx configured"

# Step 14: Configure firewall
print_status "Configuring firewall..."
ufw allow ssh
ufw allow 'Nginx Full'
ufw --force enable
print_success "Firewall configured"

# Step 15: Start services
print_status "Starting services..."
systemctl start flowise
systemctl start nginx
print_success "Services started"

# Step 16: Setup SSL (optional)
print_status "Setting up SSL certificate..."
print_warning "To setup SSL, run: sudo certbot --nginx -d your-domain.com"

print_success "Flowise VPS deployment completed!"
echo ""
echo "🎉 DEPLOYMENT SUMMARY"
echo "===================="
echo "✅ Flowise installed in: $APP_DIR"
echo "✅ Service user: $SERVICE_USER"
echo "✅ Database: PostgreSQL (flowise)"
echo "✅ Web server: Nginx"
echo "✅ SSL: Ready for setup"
echo ""
echo "📋 NEXT STEPS:"
echo "1. Update your domain in Nginx config"
echo "2. Run SSL setup: sudo certbot --nginx -d your-domain.com"
echo "3. Access Flowise at: http://your-domain.com"
echo "4. Default login: admin / admin123"
echo ""
echo "🔧 MANAGEMENT COMMANDS:"
echo "• Start: sudo systemctl start flowise"
echo "• Stop: sudo systemctl stop flowise"
echo "• Restart: sudo systemctl restart flowise"
echo "• Status: sudo systemctl status flowise"
echo "• Logs: sudo journalctl -u flowise -f"
