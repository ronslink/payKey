# PayKey Deployment Log

## Overview
This log documents the deployment of the PayKey backend to DigitalOcean, including the migration to a Managed PostgreSQL database and SSL configuration.

## Deployment Timeline (2025-12-23)

### 1. Infrastructure Setup
- **Droplet Created**: `paykey-prod` (Ubuntu 24.04, 2GB RAM, London Region).
- **SSH Access**: Key `paykey-deploy` generated and authorized.
- **Docker**: Installed Docker 29.1.3 and Docker Compose v2.

### 2. Database Setup
- **Initial Plan**: Local PostgreSQL Docker container (Removed).
- **Final Plan**: DigitalOcean Managed PostgreSQL 17 (`paykey-db`).
- **Configuration**:
    - Region: London (lon1)
    - Plan: 1GB RAM, 1 vCPU ($15/mo)
    - Connection: SSL Required (`sslmode=require` or CA validation)

### 3. Application Deployment
- **Docker Image**: `rondockerlink/paykey-backend:latest`
    - Built for `linux/amd64` platform.
    - Updated `app.module.ts` to support `DATABASE_URL` and SSL.
    - Pushed to Docker Hub.
- **Server Configuration (`/opt/paykey/`)**:
    - `docker-compose.yml`: Services `backend` and `redis`. `db` service removed.
    - `.env`: Contains sensitive secrets (Database, JWT).

### 4. Resolving SSL Connection Issues (Backend)
- **Issue**: "Self-signed certificate in certificate chain" error when connecting to Managed DB.
- **Solution**:
    1. Downloaded DigitalOcean CA Cert to server (`/opt/paykey/ca-certificate.crt`).
    2. Mounted cert into Docker container at `/app/ca-certificate.crt`.
    3. Set `NODE_EXTRA_CA_CERTS=/app/ca-certificate.crt` env var.
    4. Node.js now trusts the Managed DB certificate globally.

### 5. Domain & HTTPS Setup
- **Domain**: `paydome.co` (Registered separately).
- **DNS**: Configured `A` record for `api.paydome.co` pointing to `46.101.95.200`.
- **SSL**: Generated Let's Encrypt certificate via Certbot (`certbot --nginx -d api.paydome.co`).
- **Status**: Secure HTTPS access verified.

### 6. Verification
- **Backed**: Running and connected to DB.
- **Holidays**: Successfully seeded to the new database on startup.
- **API**: `curl https://api.paydome.co/` returns "Hello World!".

## Key Files & Locations (Server)
- **App Directory**: `/opt/paykey/`
- **Compose URL**: `/opt/paykey/docker-compose.yml`
- **Secrets**: `/opt/paykey/.env`
- **CA Cert**: `/opt/paykey/ca-certificate.crt`

## Maintenance Commands
```bash
# SSH into Server
ssh -i ~/.ssh/paykey_deploy root@46.101.95.200

# View Logs
cd /opt/paykey && docker compose logs -f backend

# Update & Redeploy
cd /opt/paykey && docker compose pull && docker compose up -d
```
