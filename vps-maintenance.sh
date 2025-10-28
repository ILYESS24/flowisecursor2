#!/bin/bash

# FLOWISE VPS MAINTENANCE SCRIPT
# Maintenance and management utilities for VPS deployment

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

APP_NAME="flowise"
APP_DIR="/opt/flowise"
SERVICE_USER="flowise"

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

# Function to show usage
show_usage() {
    echo "Flowise VPS Maintenance Script"
    echo "Usage: $0 [COMMAND]"
    echo ""
    echo "Commands:"
    echo "  start       - Start Flowise service"
    echo "  stop        - Stop Flowise service"
    echo "  restart     - Restart Flowise service"
    echo "  status      - Show service status"
    echo "  logs        - Show service logs"
    echo "  update      - Update Flowise from repository"
    echo "  backup      - Backup database and files"
    echo "  restore     - Restore from backup"
    echo "  ssl         - Setup SSL certificate"
    echo "  monitor     - Show system monitoring"
    echo "  cleanup     - Clean up old logs and files"
    echo ""
}

# Start service
start_service() {
    print_status "Starting Flowise service..."
    systemctl start flowise
    print_success "Flowise service started"
}

# Stop service
stop_service() {
    print_status "Stopping Flowise service..."
    systemctl stop flowise
    print_success "Flowise service stopped"
}

# Restart service
restart_service() {
    print_status "Restarting Flowise service..."
    systemctl restart flowise
    print_success "Flowise service restarted"
}

# Show status
show_status() {
    print_status "Flowise service status:"
    systemctl status flowise --no-pager
    echo ""
    print_status "Nginx status:"
    systemctl status nginx --no-pager
    echo ""
    print_status "PostgreSQL status:"
    systemctl status postgresql --no-pager
}

# Show logs
show_logs() {
    print_status "Showing Flowise logs (Ctrl+C to exit):"
    journalctl -u flowise -f
}

# Update application
update_app() {
    print_status "Updating Flowise from repository..."
    
    # Stop service
    systemctl stop flowise
    
    # Backup current version
    cp -r "$APP_DIR" "$APP_DIR.backup.$(date +%Y%m%d_%H%M%S)"
    
    # Update from repository
    cd "$APP_DIR"
    sudo -u "$SERVICE_USER" git pull origin main
    
    # Install dependencies
    sudo -u "$SERVICE_USER" pnpm install
    
    # Build application
    sudo -u "$SERVICE_USER" pnpm build
    
    # Start service
    systemctl start flowise
    
    print_success "Flowise updated successfully"
}

# Backup function
backup_data() {
    BACKUP_DIR="/opt/backups/flowise"
    BACKUP_FILE="flowise_backup_$(date +%Y%m%d_%H%M%S).tar.gz"
    
    print_status "Creating backup..."
    
    mkdir -p "$BACKUP_DIR"
    
    # Backup database
    sudo -u postgres pg_dump flowise > "$BACKUP_DIR/flowise_db.sql"
    
    # Backup application data
    tar -czf "$BACKUP_DIR/$BACKUP_FILE" \
        -C "$APP_DIR" \
        .flowise \
        uploads \
        .env
    
    print_success "Backup created: $BACKUP_DIR/$BACKUP_FILE"
}

# Restore function
restore_data() {
    if [ -z "$1" ]; then
        print_error "Please specify backup file path"
        exit 1
    fi
    
    BACKUP_FILE="$1"
    
    if [ ! -f "$BACKUP_FILE" ]; then
        print_error "Backup file not found: $BACKUP_FILE"
        exit 1
    fi
    
    print_warning "This will restore from backup. Continue? (y/N)"
    read -r response
    if [[ ! "$response" =~ ^[Yy]$ ]]; then
        print_status "Restore cancelled"
        exit 0
    fi
    
    print_status "Restoring from backup..."
    
    # Stop service
    systemctl stop flowise
    
    # Extract backup
    tar -xzf "$BACKUP_FILE" -C "$APP_DIR"
    
    # Restore database
    sudo -u postgres psql flowise < "$BACKUP_FILE.sql"
    
    # Start service
    systemctl start flowise
    
    print_success "Restore completed"
}

# Setup SSL
setup_ssl() {
    if [ -z "$1" ]; then
        print_error "Please specify domain name"
        exit 1
    fi
    
    DOMAIN="$1"
    
    print_status "Setting up SSL certificate for $DOMAIN..."
    
    # Update Nginx config with domain
    sed -i "s/your-domain.com/$DOMAIN/g" /etc/nginx/sites-available/flowise
    
    # Reload Nginx
    systemctl reload nginx
    
    # Get SSL certificate
    certbot --nginx -d "$DOMAIN" --non-interactive --agree-tos --email admin@$DOMAIN
    
    print_success "SSL certificate setup completed"
}

# System monitoring
show_monitoring() {
    print_status "System Monitoring"
    echo "===================="
    echo ""
    
    print_status "CPU Usage:"
    top -bn1 | grep "Cpu(s)" | awk '{print $2}' | cut -d'%' -f1
    echo ""
    
    print_status "Memory Usage:"
    free -h
    echo ""
    
    print_status "Disk Usage:"
    df -h
    echo ""
    
    print_status "Service Status:"
    systemctl is-active flowise nginx postgresql
    echo ""
    
    print_status "Network Connections:"
    netstat -tlnp | grep -E ':(80|443|3000|5432)'
}

# Cleanup function
cleanup_system() {
    print_status "Cleaning up system..."
    
    # Clean old logs
    journalctl --vacuum-time=7d
    
    # Clean package cache
    apt autoremove -y
    apt autoclean
    
    # Clean old backups (keep last 7 days)
    find /opt/backups/flowise -name "*.tar.gz" -mtime +7 -delete
    
    print_success "Cleanup completed"
}

# Main script logic
case "$1" in
    start)
        start_service
        ;;
    stop)
        stop_service
        ;;
    restart)
        restart_service
        ;;
    status)
        show_status
        ;;
    logs)
        show_logs
        ;;
    update)
        update_app
        ;;
    backup)
        backup_data
        ;;
    restore)
        restore_data "$2"
        ;;
    ssl)
        setup_ssl "$2"
        ;;
    monitor)
        show_monitoring
        ;;
    cleanup)
        cleanup_system
        ;;
    *)
        show_usage
        exit 1
        ;;
esac
