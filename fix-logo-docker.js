// Script pour modifier le logo Flowise en "AI Assistant" dans le conteneur Docker
const fs = require('fs')
const path = require('path')

// Chemin vers le fichier Logo.jsx dans le conteneur
const logoPath = '/usr/local/lib/node_modules/flowise/packages/ui/src/ui-component/extended/Logo.jsx'

// Nouveau contenu avec "AI Assistant"
const newLogoContent = `import { useSelector } from 'react-redux'
import { Typography } from '@mui/material'

// ==============================|| LOGO ||============================== //

const Logo = () => {
    const customization = useSelector((state) => state.customization)

    return (
        <div style={{ alignItems: 'center', display: 'flex', flexDirection: 'row', marginLeft: '10px' }}>
            <Typography
                variant="h4"
                sx={{
                    fontWeight: 'bold',
                    color: customization.isDarkMode ? '#ffffff' : '#000000',
                    cursor: 'pointer',
                    '&:hover': {
                        opacity: 0.8
                    }
                }}
            >
                AI Assistant
            </Typography>
        </div>
    )
}

export default Logo`

try {
    // Écrire le nouveau contenu
    fs.writeFileSync(logoPath, newLogoContent)
    console.log('✅ Logo modifié avec succès !')
    console.log('🎯 "Flowise" remplacé par "AI Assistant"')
} catch (error) {
    console.error('❌ Erreur lors de la modification du logo:', error.message)
    process.exit(1)
}
