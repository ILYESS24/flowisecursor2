# Flowise Vercel Deployment Guide

## 🚀 Déploiement Frontend sur Vercel

### Prérequis
- Compte Vercel
- Node.js 18+
- pnpm installé

### Étapes de déploiement

#### 1. Préparation
```bash
# Installer les dépendances
pnpm install

# Build du projet complet
pnpm build
```

#### 2. Déploiement Frontend uniquement
```bash
cd packages/ui

# Installer Vercel CLI
npm i -g vercel

# Déployer
vercel --prod
```

#### 3. Configuration des variables d'environnement
Dans le dashboard Vercel, ajouter :
- `REACT_APP_API_URL` : URL de votre backend (ex: https://your-backend.railway.app)

### 🔧 Configuration Backend séparé

Pour une solution complète, déployez le backend sur :
- **Railway** (recommandé)
- **Render**
- **Heroku**

### 📊 Architecture recommandée

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Frontend      │    │   Backend       │    │   Database      │
│   (Vercel)      │◄──►│   (Railway)     │◄──►│   (Supabase)    │
│   React App     │    │   Node.js API   │    │   PostgreSQL    │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

### ⚠️ Limitations Vercel

- Pas de base de données persistante
- Pas de processus long-running
- Limite de 10s pour les fonctions serverless
- Pas de WebSockets natifs

### 🎯 Alternative complète : Railway

Pour déployer Flowise complet :
```bash
# Installer Railway CLI
npm i -g @railway/cli

# Déployer
railway login
railway init
railway up
```

### 📝 Notes importantes

1. **Base de données** : Utilisez PostgreSQL sur Supabase/PlanetScale
2. **Uploads** : Configurez un service de stockage (AWS S3, Cloudinary)
3. **WebSockets** : Utilisez Pusher ou Socket.io avec Redis
4. **Variables d'environnement** : Configurez toutes les clés API nécessaires
