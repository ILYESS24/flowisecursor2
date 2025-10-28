#!/usr/bin/env node

// Render-specific start script for Flowise
const { spawn } = require('child_process')
const path = require('path')

// Set environment variables for production
process.env.NODE_ENV = process.env.NODE_ENV || 'production'
process.env.PORT = process.env.PORT || '10000'

// Start the Flowise server
const serverPath = path.join(__dirname, '..', 'dist', 'index.js')

console.log('🚀 Starting Flowise on Render...')
console.log(`📁 Server path: ${serverPath}`)
console.log(`🌐 Port: ${process.env.PORT}`)
console.log(`🔧 Environment: ${process.env.NODE_ENV}`)

// Start the server
const server = spawn('node', [serverPath], {
    stdio: 'inherit',
    env: process.env
})

server.on('error', (err) => {
    console.error('❌ Failed to start server:', err)
    process.exit(1)
})

server.on('exit', (code) => {
    console.log(`🔄 Server exited with code ${code}`)
    process.exit(code)
})

// Handle graceful shutdown
process.on('SIGTERM', () => {
    console.log('🛑 Received SIGTERM, shutting down gracefully...')
    server.kill('SIGTERM')
})

process.on('SIGINT', () => {
    console.log('🛑 Received SIGINT, shutting down gracefully...')
    server.kill('SIGINT')
})
