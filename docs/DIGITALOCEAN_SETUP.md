# DigitalOcean Deployment Guide

## Prerequisites
- DigitalOcean account ([sign up](https://cloud.digitalocean.com/registrations/new))
- Docker Hub account ([sign up](https://hub.docker.com/signup))
- Domain name (optional, for HTTPS)

---

## Step 1: Create a Droplet

1. Go to **DigitalOcean Control Panel**
2. Click **Create → Droplets**
3. Select:
   - **Region**: Choose closest to your users (e.g., London, Frankfurt)
   - **Image**: Ubuntu 24.04 LTS
   - **Size**: Basic → $12/mo (2GB RAM, 1 CPU) minimum
   - **Authentication**: SSH Key (recommended)
4. Click **Create Droplet**
5. Note the **IP address** (e.g., `143.198.123.45`)

---

## Step 2: Set Up SSH Access

```bash
# On your local machine (Mac)

# Generate SSH key for deployment
ssh-keygen -t ed25519 -C "paykey-deploy" -f ~/.ssh/paykey_deploy

# Copy public key to droplet (replace IP)
ssh-copy-id -i ~/.ssh/paykey_deploy.pub root@YOUR_DROPLET_IP

# Test connection
ssh -i ~/.ssh/paykey_deploy root@YOUR_DROPLET_IP
```

---

## Step 3: Install Docker on Droplet

```bash
# SSH into droplet
ssh root@YOUR_DROPLET_IP

# Install Docker
curl -fsSL https://get.docker.com | sh

# Install Docker Compose
apt install -y docker-compose-plugin

# Verify
docker --version
docker compose version
```

---

## Step 4: Set Up Application Directory

```bash
# Create app directory
mkdir -p /opt/paykey
cd /opt/paykey

# Create docker-compose.yml
cat > docker-compose.yml << 'EOF'
version: '3.8'

services:
  backend:
    image: YOUR_DOCKER_USERNAME/paykey-backend:latest
    restart: unless-stopped
    ports:
      - "3000:3000"
    environment:
      - NODE_ENV=production
      - DB_HOST=db
      - DB_PORT=5432
      - DB_USERNAME=paykey
      - DB_PASSWORD=${DB_PASSWORD}
      - DB_DATABASE=paykey
      - JWT_SECRET=${JWT_SECRET}
      - REDIS_HOST=redis
      - REDIS_PORT=6379
    depends_on:
      db:
        condition: service_healthy
      redis:
        condition: service_started

  db:
    image: postgres:17-alpine
    restart: unless-stopped
    environment:
      - POSTGRES_USER=paykey
      - POSTGRES_PASSWORD=${DB_PASSWORD}
      - POSTGRES_DB=paykey
    volumes:
      - postgres_data:/var/lib/postgresql/data
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U paykey"]
      interval: 5s
      timeout: 5s
      retries: 5

  redis:
    image: redis:7-alpine
    restart: unless-stopped
    volumes:
      - redis_data:/data

volumes:
  postgres_data:
  redis_data:
EOF
```

---

## Step 5: Create Environment File

```bash
# Generate secure passwords
DB_PASSWORD=$(openssl rand -base64 32)
JWT_SECRET=$(openssl rand -base64 64)

# Create .env file
cat > .env << EOF
DB_PASSWORD=${DB_PASSWORD}
JWT_SECRET=${JWT_SECRET}
EOF

# Secure the file
chmod 600 .env

# Show the values (save these somewhere safe!)
echo "DB_PASSWORD: ${DB_PASSWORD}"
echo "JWT_SECRET: ${JWT_SECRET}"
```

---

## Step 6: Set Up GitHub Secrets

Go to **github.com/YOUR_USERNAME/payKey → Settings → Secrets → Actions**

Add these secrets:

| Secret | Value |
|--------|-------|
| `DOCKER_USERNAME` | Your Docker Hub username |
| `DOCKER_PASSWORD` | Docker Hub access token |
| `DO_HOST` | Your droplet IP (e.g., `143.198.123.45`) |
| `DO_USERNAME` | `root` |
| `DO_SSH_KEY` | Contents of `~/.ssh/paykey_deploy` (private key) |

---

## Step 7: First Deployment

### Option A: Manual (first time)
```bash
# On the droplet
cd /opt/paykey
docker compose pull
docker compose up -d

# Check status
docker compose ps
docker compose logs -f backend
```

### Option B: Automatic (after push to main)
Push code to `main` branch → GitHub Actions deploys automatically

---

## Step 8: Set Up Domain & HTTPS (Optional)

```bash
# Install Nginx
apt install -y nginx

# Install Certbot
apt install -y certbot python3-certbot-nginx

# Create Nginx config
cat > /etc/nginx/sites-available/paykey << 'EOF'
server {
    listen 80;
    server_name api.yourdomain.com;

    location / {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_cache_bypass $http_upgrade;
    }
}
EOF

# Enable site
ln -s /etc/nginx/sites-available/paykey /etc/nginx/sites-enabled/
nginx -t && systemctl reload nginx

# Get SSL certificate
certbot --nginx -d api.yourdomain.com
```

---

## Useful Commands

```bash
# View logs
docker compose logs -f backend

# Restart services
docker compose restart backend

# Pull latest and restart
docker compose pull && docker compose up -d

# Database backup
docker compose exec db pg_dump -U paykey paykey > backup.sql

# Check disk space
df -h
```

---

## Troubleshooting

| Issue | Solution |
|-------|----------|
| Container won't start | `docker compose logs backend` |
| Database connection failed | Check `DB_PASSWORD` in `.env` |
| Port 3000 not accessible | `ufw allow 3000` or check firewall |
| Disk full | `docker system prune -a` |
