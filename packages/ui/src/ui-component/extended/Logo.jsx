import { useSelector } from 'react-redux'
import { Typography } from '@mui/material'

// ==============================|| LOGO ||============================== //

const Logo = () => {
    const customization = useSelector((state) => state.customization)

    return (
        <div style={{ alignItems: 'center', display: 'flex', flexDirection: 'row', marginLeft: '10px' }}>
            <Typography
                variant='h4'
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

export default Logo
