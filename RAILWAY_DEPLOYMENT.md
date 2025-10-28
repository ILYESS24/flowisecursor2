# Railway Configuration for Flowise

## 🚀 Déploiement Railway - Guide Complet

### Prérequis
- Compte Railway (railway.app)
- GitHub repository
- Node.js 18+

### Étapes de déploiement

#### 1. Installation Railway CLI
```bash
npm install -g @railway/cli
```

#### 2. Connexion et initialisation
```bash
railway login
railway init
```

#### 3. Configuration des variables d'environnement
```bash
railway variables set NODE_ENV=production
railway variables set DATABASE_URL=${{Postgres.DATABASE_URL}}
railway variables set FLOWISE_USERNAME=admin
railway variables set FLOWISE_PASSWORD=your_password
```

#### 4. Déploiement
```bash
railway up
```

### 🔧 Configuration automatique

Railway détectera automatiquement :
- ✅ Monorepo avec pnpm
- ✅ Scripts de build (turbo run build)
- ✅ Port d'écoute (3000)
- ✅ Base de données PostgreSQL

### 📊 Avantages Railway

- **Déploiement en 2 minutes**
- **Base de données PostgreSQL incluse**
- **Monitoring et logs intégrés**
- **Variables d'environnement sécurisées**
- **Support des WebSockets**
- **Stockage persistant**
- **Mise à l'échelle automatique**

### 💰 Coûts Railway

- **Plan Hobby** : $5/mois
  - 1 service
  - 1 base de données
  - 8GB RAM
  - 100GB stockage

- **Plan Pro** : $20/mois
  - Services illimités
  - Bases de données illimitées
  - 32GB RAM
  - 1TB stockage

### 🎯 Pourquoi Railway > Autres

1. **Simplicité** : Configuration minimale
2. **Performance** : Optimisé pour Node.js
3. **Fiabilité** : Infrastructure robuste
4. **Prix** : Excellent rapport qualité/prix
5. **Support** : Communauté active
