#!/bin/bash
set -e

# Paydome Website Deployment Script

echo "🚀 Starting Paydome Website Deployment..."

# 1. Pull latest code (assuming this runs in the repo)
# git pull origin main

# 2. Rebuild and restart containers
echo "📦 Building and restarting containers..."
docker compose -f docker-compose.prod.yml up -d --build

# 3. Prune unused images to save space
echo "🧹 Cleaning up..."
docker image prune -f

echo "✅ Deployment complete! Website should be active on http://localhost or your public IP."
echo "   Ensure your DNS A record for paydome.co points to this server's IP."
