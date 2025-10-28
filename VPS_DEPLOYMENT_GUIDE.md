# 🚀 GUIDE DE DÉPLOIEMENT VPS - FLOWISE AI ASSISTANT

## 📋 PRÉREQUIS

### Serveur VPS requis :

- **OS** : Ubuntu 20.04+ ou Debian 11+
- **RAM** : Minimum 2GB (recommandé 4GB+)
- **CPU** : 2 vCPU minimum
- **Stockage** : 20GB minimum
- **Accès** : SSH avec sudo

### Informations nécessaires :

- **Nom de domaine** ou IP publique du serveur
- **Email** pour les certificats SSL
- **Mot de passe** pour l'admin Flowise
- **Mot de passe** pour la base de données

## 🛠️ ÉTAPES DE DÉPLOIEMENT

### 1. Connexion au VPS

```bash
ssh username@your-server-ip
```

### 2. Téléchargement du projet

```bash
# Cloner le projet avec vos modifications
git clone https://github.com/VOTRE_USERNAME/flowisecursor.git
cd flowisecursor

# Ou télécharger depuis votre machine locale
scp -r Flowise-main username@your-server-ip:/home/username/
```

### 3. Lancement du déploiement automatique

```bash
# Rendre le script exécutable
chmod +x deploy-vps-complete.sh

# Lancer le déploiement
./deploy-vps-complete.sh
```

### 4. Configuration interactive

Le script va vous demander :

- **Domaine** : `votre-domaine.com` ou `IP-DU-SERVEUR`
- **Email** : `votre@email.com`
- **Mot de passe admin** : `votre-mot-de-passe-securise`
- **Mot de passe DB** : `mot-de-passe-db-securise`

## 🎯 RÉSULTAT ATTENDU

Après déploiement, vous aurez :

### ✅ Services actifs :

- **Flowise** : Port 3000 (interne)
- **PostgreSQL** : Base de données
- **Nginx** : Reverse proxy + SSL
- **SSL** : Certificat Let's Encrypt automatique

### ✅ Fonctionnalités :

- **Logo "AI Assistant"** au lieu de "Flowise"
- **HTTPS** automatique avec redirection
- **Rate limiting** pour la sécurité
- **Headers de sécurité** configurés
- **Monitoring** et logs

### ✅ Accès :

- **URL** : `https://votre-domaine.com`
- **Admin** : `admin` / `votre-mot-de-passe`
- **API** : `https://votre-domaine.com/api/v1/`

## 🛠️ MAINTENANCE

### Commandes utiles :

```bash
# Démarrer les services
./vps-maintenance.sh start

# Arrêter les services
./vps-maintenance.sh stop

# Redémarrer les services
./vps-maintenance.sh restart

# Voir les logs
./vps-maintenance.sh logs

# Mettre à jour
./vps-maintenance.sh update

# Sauvegarder la base de données
./vps-maintenance.sh backup
```

### Surveillance :

```bash
# Vérifier l'état des conteneurs
docker-compose -f docker-compose-vps.yml ps

# Voir les logs en temps réel
docker-compose -f docker-compose-vps.yml logs -f

# Vérifier l'espace disque
df -h

# Vérifier la mémoire
free -h
```

## 🔧 DÉPANNAGE

### Problèmes courants :

#### 1. Services ne démarrent pas

```bash
# Vérifier les logs
docker-compose -f docker-compose-vps.yml logs

# Redémarrer
docker-compose -f docker-compose-vps.yml restart
```

#### 2. SSL ne fonctionne pas

```bash
# Renouveler le certificat
sudo certbot renew

# Vérifier la configuration Nginx
sudo nginx -t
```

#### 3. Problème de permissions

```bash
# Corriger les permissions
sudo chown -R $USER:$USER /opt/flowise-ai-assistant
```

#### 4. Port déjà utilisé

```bash
# Vérifier les ports utilisés
sudo netstat -tlnp | grep :80
sudo netstat -tlnp | grep :443
```

## 📊 MONITORING

### Métriques importantes :

- **CPU** : < 80%
- **RAM** : < 80%
- **Disque** : < 90%
- **Connexions** : Surveiller les logs

### Alertes recommandées :

- Service down
- Espace disque < 10%
- RAM > 90%
- Erreurs SSL

## 🔒 SÉCURITÉ

### Bonnes pratiques :

- ✅ **Firewall** configuré (ports 22, 80, 443)
- ✅ **SSL** automatique avec Let's Encrypt
- ✅ **Rate limiting** activé
- ✅ **Headers de sécurité** configurés
- ✅ **Mots de passe** forts
- ✅ **Mises à jour** régulières

### Recommandations :

- Changer le port SSH (22)
- Utiliser des clés SSH
- Configurer fail2ban
- Surveiller les logs d'accès

## 🎉 FÉLICITATIONS !

Votre **AI Assistant** personnalisé est maintenant déployé et accessible via HTTPS avec toutes vos modifications !

**URL d'accès** : `https://votre-domaine.com`
**Logo personnalisé** : "AI Assistant" au lieu de "Flowise"
**Sécurité** : SSL + Rate limiting + Headers de sécurité
**Maintenance** : Scripts automatisés inclus
