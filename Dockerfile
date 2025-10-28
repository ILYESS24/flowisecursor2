# Dockerfile basé sur l'image officielle Flowise
FROM flowiseai/flowise:latest

# Copier notre logo personnalisé
COPY packages/ui/src/ui-component/extended/Logo.jsx /app/packages/ui/src/ui-component/extended/Logo.jsx

# Exposer le port
EXPOSE 3000

# Variables d'environnement
ENV NODE_ENV=production
ENV PORT=3000

# La commande de démarrage est déjà définie dans l'image de base