# Authentication Feature

## Overview
JWT-based authentication for user registration and login.

## Environment Variables
```env
JWT_SECRET=your-super-secret-jwt-key-change-this-in-production
```

## API Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/auth/register` | Register new user |
| POST | `/auth/login` | Login and get JWT token |

### Register Request
```json
{
  "email": "user@example.com",
  "password": "SecurePass123!",
  "firstName": "John",
  "lastName": "Doe"
}
```

### Login Request
```json
{
  "email": "user@example.com",
  "password": "SecurePass123!"
}
```

### Response (Both)
```json
{
  "access_token": "eyJhbGciOiJIUzI1NiIs...",
  "user": {
    "id": "uuid",
    "email": "user@example.com",
    "firstName": "John",
    "lastName": "Doe",
    "tier": "FREE"
  }
}
```

## Mobile UI
- **Login Page**: `mobile/lib/features/auth/presentation/pages/login_page.dart`
- **Register Page**: `mobile/lib/features/auth/presentation/pages/register_page.dart`

## Database Entities
- `User` - `backend/src/modules/users/entities/user.entity.ts`

## Current Configuration Status
- ✅ JWT authentication working
- ✅ User registration with email validation
- ✅ Login with password verification
- ✅ Token stored in secure storage (mobile)

## Known Gaps
| Gap | Status |
|-----|--------|
| Password Reset | ❌ Not implemented |
| Email Verification | ❌ Not implemented |
| OAuth (Google/Apple) | ❌ Not implemented |
