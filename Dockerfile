# Dockerfile pour Koyeb avec port forcé
FROM flowiseai/flowise:latest

# Copier notre logo personnalisé
COPY packages/ui/src/ui-component/extended/Logo.jsx /app/packages/ui/src/ui-component/extended/Logo.jsx

# Variables d'environnement
ENV NODE_ENV=production
ENV PORT=3000

# Exposer le port 3000
EXPOSE 3000

# Forcer Flowise à écouter sur le port 3000
CMD ["sh", "-c", "PORT=3000 flowise start"]