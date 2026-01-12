# PayKey MVP Deployment Guide

## Prerequisites

### Backend Requirements
- Node.js 18+ 
- PostgreSQL 15+
- Redis (optional, for caching)

### Mobile Requirements
- Flutter 3.10+
- Android Studio / Xcode
- Dart SDK

## Backend Setup

### 1. Database Setup
```bash
# Start PostgreSQL using Docker
docker-compose up -d db

# Or install PostgreSQL locally and create database
createdb paykey
```

### 2. Backend Installation
```bash
cd backend

# Install dependencies
npm install

# Copy environment file
cp .env.example .env

# Edit .env with your configuration
# DB_HOST=localhost
# DB_PORT=5435
# DB_USERNAME=postgres
# DB_PASSWORD=admin
# DB_NAME=paykey
# JWT_SECRET=your-super-secret-jwt-key
# MPESA_CONSUMER_KEY=your-mpesa-key
# MPESA_CONSUMER_SECRET=your-mpesa-secret
```

### 3. Database Migrations
```bash
# The app uses TypeORM synchronize for development
# For production, disable synchronize and use migrations
npm run start:dev
```

### 4. Start Backend
```bash
# Development
npm run start:dev

# Production
npm run build
npm run start:prod
```

## Mobile App Setup

### 1. Flutter Setup
```bash
cd mobile

# Install dependencies
flutter pub get

# For Android
flutter build apk

# For iOS
flutter build ios
```

### 2. Configuration
Update the API base URL in `lib/core/network/api_service.dart`:
```dart
static const String baseUrl = 'http://your-backend-url:3000';
```

### 3. Run Mobile App
```bash
# Android
flutter run

# iOS
flutter run -d ios
```

## Environment Variables

### Backend (.env)
```env
# Database
DB_HOST=localhost
DB_PORT=5435
DB_USERNAME=postgres
DB_PASSWORD=admin
DB_NAME=paykey

# JWT
JWT_SECRET=your-super-secret-jwt-key

# M-Pesa (Sandbox)
MPESA_CONSUMER_KEY=your-consumer-key
MPESA_CONSUMER_SECRET=your-consumer-secret
MPESA_SHORTCODE=your-shortcode
MPESA_PASSKEY=your-passkey
MPESA_CALLBACK_URL=https://your-domain.com/payments/callback

# Stripe (Optional)
STRIPE_SECRET_KEY=your-stripe-secret-key
```

## Testing the MVP

### 1. User Registration & Login
- Open mobile app
- Register a new account
- Login with credentials

### 2. Worker Management
- Navigate to Workers section
- Add a new worker with details
- Verify worker appears in list

### 3. Subscription Enforcement
- Try adding workers beyond your tier limit
- Verify subscription guard blocks creation
- Test 14-day trial period

### 4. Tax Calculations
- Use tax calculator with different salary amounts
- Verify PAYE, NSSF, NHIF calculations

### 5. Payment Processing
- Test M-Pesa STK push (sandbox)
- Verify payment callbacks

## Production Deployment

### Backend (AWS/Heroku/DigitalOcean)
1. Set up PostgreSQL database
2. Configure environment variables
3. Deploy built application
4. Set up SSL certificates
5. Configure domain and DNS

### Mobile App (App Store/Play Store)
1. Build release versions
2. Test thoroughly on devices
3. Submit to app stores
4. Configure app store listings

## Monitoring & Maintenance

### Backend Monitoring
- Set up logging (Winston/Morgan)
- Configure health checks
- Monitor database performance
- Set up error tracking (Sentry)

### Mobile App Updates
- Regular Flutter updates
- API compatibility checks
- User feedback collection
- Performance monitoring

## Security Considerations

### Backend Security
- Use strong JWT secrets
- Implement rate limiting
- Validate all inputs
- Use HTTPS in production
- Regular security updates

### Mobile Security
- Secure storage for tokens
- Certificate pinning
- Input validation
- Regular security audits

## Scaling Considerations

### Database
- Add proper indexes
- Consider read replicas
- Implement connection pooling

### Backend
- Add load balancing
- Implement caching (Redis)
- Use background jobs for payments

### Mobile
- Implement offline capabilities
- Add data synchronization
- Optimize image loading