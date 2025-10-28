# Dockerfile optimisé pour Render
FROM node:20-alpine

# Installer pnpm
RUN npm install -g pnpm

# Définir le répertoire de travail
WORKDIR /app

# Copier les fichiers de configuration
COPY package.json pnpm-lock.yaml pnpm-workspace.yaml turbo.json ./

# Copier les packages
COPY packages/ ./packages/

# Installer les dépendances
RUN pnpm install --frozen-lockfile

# Build l'application
RUN pnpm build

# Exposer le port
EXPOSE 3000

# Variables d'environnement
ENV NODE_ENV=production
ENV PORT=3000

# Commande de démarrage
CMD ["pnpm", "start"]