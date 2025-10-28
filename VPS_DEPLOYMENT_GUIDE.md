# 🚀 Guide de Déploiement Flowise sur VPS

## 📋 Prérequis

- VPS avec Ubuntu 20.04+ ou Debian 11+
- Accès root ou sudo
- Domaine configuré (optionnel)
- Au moins 2GB RAM et 20GB SSD

## 🛠️ Méthodes de Déploiement

### Méthode 1: Script Automatique (Recommandé)

```bash
# 1. Télécharger le script de déploiement
wget https://raw.githubusercontent.com/ILYESS24/flowisecursor/main/deploy-vps.sh

# 2. Rendre le script exécutable
chmod +x deploy-vps.sh

# 3. Exécuter le déploiement
sudo ./deploy-vps.sh
```

### Méthode 2: Docker Compose

```bash
# 1. Installer Docker et Docker Compose
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker $USER

# 2. Cloner le repository
git clone https://github.com/ILYESS24/flowisecursor.git
cd flowisecursor

# 3. Configurer les variables d'environnement
cp render.env.example .env
nano .env

# 4. Démarrer avec Docker Compose
docker-compose -f docker-compose-vps.yml up -d
```

### Méthode 3: Installation Manuelle

```bash
# 1. Mettre à jour le système
sudo apt update && sudo apt upgrade -y

# 2. Installer Node.js 20
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt install -y nodejs

# 3. Installer pnpm
sudo npm install -g pnpm

# 4. Installer PostgreSQL
sudo apt install -y postgresql postgresql-contrib

# 5. Cloner et configurer Flowise
git clone https://github.com/ILYESS24/flowisecursor.git
cd flowisecursor
pnpm install
pnpm build

# 6. Configurer la base de données
sudo -u postgres psql -c "CREATE DATABASE flowise;"
sudo -u postgres psql -c "CREATE USER flowise WITH PASSWORD 'your_password';"
sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE flowise TO flowise;"
```

## 🔧 Configuration

### Variables d'Environnement

Créer un fichier `.env` dans le répertoire racine :

```bash
NODE_ENV=production
PORT=3000
DATABASE_URL=postgresql://flowise:password@localhost:5432/flowise
FLOWISE_USERNAME=admin
FLOWISE_PASSWORD=your_secure_password
FLOWISE_SECRETKEY=your-secret-key-here
APIKEY_PATH=/opt/flowise/.flowise
CORS_ORIGINS=*
ALLOWED_IFRAME_ORIGINS=*
DISABLE_TELEMETRY=true
LOG_LEVEL=info
```

### Configuration Nginx

```bash
# Copier la configuration Nginx
sudo cp nginx-vps.conf /etc/nginx/sites-available/flowise

# Activer le site
sudo ln -s /etc/nginx/sites-available/flowise /etc/nginx/sites-enabled/

# Tester la configuration
sudo nginx -t

# Recharger Nginx
sudo systemctl reload nginx
```

## 🔒 Sécurité

### Configuration du Firewall

```bash
# Activer UFW
sudo ufw enable

# Autoriser SSH
sudo ufw allow ssh

# Autoriser HTTP/HTTPS
sudo ufw allow 'Nginx Full'

# Vérifier le statut
sudo ufw status
```

### Configuration SSL avec Let's Encrypt

```bash
# Installer Certbot
sudo apt install -y certbot python3-certbot-nginx

# Obtenir un certificat SSL
sudo certbot --nginx -d your-domain.com

# Vérifier le renouvellement automatique
sudo certbot renew --dry-run
```

## 📊 Monitoring et Maintenance

### Script de Maintenance

```bash
# Rendre le script exécutable
chmod +x vps-maintenance.sh

# Commandes disponibles
./vps-maintenance.sh start      # Démarrer le service
./vps-maintenance.sh stop       # Arrêter le service
./vps-maintenance.sh restart    # Redémarrer le service
./vps-maintenance.sh status     # Voir le statut
./vps-maintenance.sh logs       # Voir les logs
./vps-maintenance.sh update     # Mettre à jour
./vps-maintenance.sh backup     # Sauvegarder
./vps-maintenance.sh monitor    # Monitoring système
./vps-maintenance.sh cleanup    # Nettoyer le système
```

### Surveillance des Logs

```bash
# Logs du service Flowise
sudo journalctl -u flowise -f

# Logs Nginx
sudo tail -f /var/log/nginx/access.log
sudo tail -f /var/log/nginx/error.log

# Logs PostgreSQL
sudo tail -f /var/log/postgresql/postgresql-*.log
```

## 🔄 Mise à Jour

### Mise à jour Automatique

```bash
# Utiliser le script de maintenance
./vps-maintenance.sh update
```

### Mise à jour Manuelle

```bash
# Arrêter le service
sudo systemctl stop flowise

# Sauvegarder
./vps-maintenance.sh backup

# Mettre à jour le code
cd /opt/flowise
sudo -u flowise git pull origin main

# Installer les nouvelles dépendances
sudo -u flowise pnpm install

# Reconstruire
sudo -u flowise pnpm build

# Redémarrer le service
sudo systemctl start flowise
```

## 🚨 Dépannage

### Problèmes Courants

1. **Service ne démarre pas**
   ```bash
   sudo systemctl status flowise
   sudo journalctl -u flowise -n 50
   ```

2. **Erreur de base de données**
   ```bash
   sudo systemctl status postgresql
   sudo -u postgres psql -c "\\l"
   ```

3. **Problème de permissions**
   ```bash
   sudo chown -R flowise:flowise /opt/flowise
   ```

4. **Port déjà utilisé**
   ```bash
   sudo netstat -tlnp | grep :3000
   sudo lsof -i :3000
   ```

### Redémarrage Complet

```bash
# Arrêter tous les services
sudo systemctl stop flowise nginx postgresql

# Redémarrer PostgreSQL
sudo systemctl start postgresql

# Redémarrer Flowise
sudo systemctl start flowise

# Redémarrer Nginx
sudo systemctl start nginx

# Vérifier le statut
sudo systemctl status flowise nginx postgresql
```

## 📈 Optimisation des Performances

### Configuration PostgreSQL

```bash
# Éditer la configuration PostgreSQL
sudo nano /etc/postgresql/*/main/postgresql.conf

# Optimisations recommandées
shared_buffers = 256MB
effective_cache_size = 1GB
work_mem = 4MB
maintenance_work_mem = 64MB
```

### Configuration Nginx

```bash
# Optimisations dans nginx.conf
worker_processes auto;
worker_connections 1024;

# Gzip compression
gzip on;
gzip_vary on;
gzip_min_length 1024;
```

## 🎯 Accès à l'Application

- **URL** : `http://your-domain.com` ou `http://your-server-ip`
- **Login par défaut** : `admin` / `admin123`
- **API** : `http://your-domain.com/api/v1/`

## 📞 Support

En cas de problème :
1. Vérifier les logs : `./vps-maintenance.sh logs`
2. Vérifier le statut : `./vps-maintenance.sh status`
3. Redémarrer : `./vps-maintenance.sh restart`
4. Consulter la documentation officielle Flowise
