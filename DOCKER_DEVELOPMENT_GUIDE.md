# Docker Development Guide

## Setup

### Prerequisites
- Docker installed
- Docker Compose installed

### Environment Configuration

Create a `.env` file in your `backend` directory with the following content:

```env
# Database Configuration
DB_HOST=db
DB_PORT=5432
DB_USER=postgres
DB_PASSWORD=admin
DB_NAME=paykey

# Redis Configuration
REDIS_HOST=redis
REDIS_PORT=6379

# Application Configuration
NODE_ENV=development
PORT=3000

# JWT Configuration
JWT_SECRET=your-super-secret-jwt-key-change-this-in-production
JWT_EXPIRATION=24h

# Other Application Secrets
# Add your application-specific environment variables here
```

## Development Workflow

### Start All Services
```bash
docker-compose up
```

### Start Services in Background
```bash
docker-compose up -d
```

### Rebuild Backend After Code Changes
```bash
docker-compose up --build backend
```

### View Logs
```bash
# All services
docker-compose logs -f

# Specific service
docker-compose logs -f backend
docker-compose logs -f db
docker-compose logs -f redis
```

### Restart Services
```bash
# Restart backend
docker-compose restart backend

# Restart all services
docker-compose restart
```

### Stop Services
```bash
# Stop all services
docker-compose down

# Stop and remove volumes (WARNING: This will delete all data)
docker-compose down -v
```

### Database Management
```bash
# Connect to database
docker-compose exec db psql -U postgres -d paykey

# View database logs
docker-compose logs db

# Reset database (WARNING: Deletes all data)
docker-compose down -v
docker-compose up -d db
```

## Service URLs

- **Backend API**: http://localhost:3000
- **PostgreSQL**: localhost:5435
- **Redis**: localhost:6379

## Development Commands

### Database Migrations
```bash
# Run migrations
docker-compose exec backend npm run typeorm:migration:run

# Generate migration
docker-compose exec backend npm run typeorm:migration:generate -- -n MigrationName

# Revert migration
docker-compose exec backend npm run typeorm:migration:revert
```

### Database Seeds
```bash
# Run seed scripts
docker-compose exec backend node dist/seed-demo-data.js
```

### Testing
```bash
# Run tests
docker-compose exec backend npm test

# Run tests with watch mode
docker-compose exec backend npm run test:watch
```

## Troubleshooting

### Common Issues

1. **Port Already in Use**
   ```bash
   # Kill processes using the port
   docker-compose down
   ```

2. **Database Connection Issues**
   ```bash
   # Check database health
   docker-compose ps
   docker-compose logs db
   ```

3. **Build Issues**
   ```bash
   # Clear Docker cache and rebuild
   docker-compose down --build --force-recreate
   ```

4. **Permission Issues (Linux/Mac)**
   ```bash
   # Fix ownership of mounted volumes
   sudo chown -R $USER:$USER .
   ```

### Useful Commands

```bash
# Clean up Docker resources
docker system prune -f

# Check Docker disk usage
docker system df

# Execute commands in running containers
docker-compose exec backend sh
docker-compose exec db psql -U postgres
```

## Production Deployment

For production, modify the docker-compose.yml:

1. Remove development volumes
2. Use production build
3. Set appropriate environment variables
4. Configure proper health checks
5. Add reverse proxy (nginx)
6. Set up SSL certificates