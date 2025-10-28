# Dockerfile simple pour Koyeb
FROM node:20-alpine

# Installer pnpm
RUN npm install -g pnpm@10.14.0

# Définir le répertoire de travail
WORKDIR /app

# Copier tous les fichiers
COPY . .

# Installer les dépendances
RUN pnpm install

# Build l'application
RUN pnpm build

# Exposer le port
EXPOSE 3000

# Variables d'environnement
ENV NODE_ENV=production
ENV PORT=3000

# Commande de démarrage
CMD ["pnpm", "start"]