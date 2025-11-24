# Authentication Configuration Guide

## Overview
This document explains the PayKey application's authentication system, including common issues and troubleshooting steps.

## Architecture

### Backend Authentication (NestJS)
- **Framework**: NestJS with TypeORM and PostgreSQL
- **Authentication Method**: JWT (JSON Web Tokens)
- **Password Hashing**: bcrypt
- **Authentication Endpoint**: `/auth/login` (returns 201 Created)

### Frontend Authentication (Flutter Web)
- **Framework**: Flutter with Dio HTTP client
- **State Management**: Riverpod
- **Token Storage**: flutter_secure_storage (web-compatible)
- **Router**: GoRouter with authentication guards

## Authentication Flow

### 1. User Login Process
```
Frontend (Flutter) → Backend (NestJS) → Database (PostgreSQL)
```

1. **Login Request**: Flutter sends POST to `/auth/login` with email/password
2. **Backend Validation**: 
   - Finds user in database
   - Compares password using bcrypt
   - Generates JWT token if valid
3. **Backend Response**: Returns `201 Created` with `access_token`
4. **Token Storage**: Flutter saves token to secure storage
5. **Redirect**: User navigated to home page

### 2. Protected API Calls
```
Frontend → Add JWT Header → Backend → Validate JWT → Return Data
```

1. **Interceptor**: Flutter adds `Authorization: Bearer <token>` to all requests
2. **Backend Validation**: JWT strategy validates token
3. **User Context**: User data extracted from JWT for request context
4. **Response**: Data returned if token valid

## Key Configuration Files

### Backend Configuration
- **Authentication Module**: `backend/src/modules/auth/auth.module.ts`
- **JWT Strategy**: `backend/src/modules/auth/jwt.strategy.ts`
- **Auth Controller**: `backend/src/modules/auth/auth.controller.ts`
- **Auth Service**: `backend/src/modules/auth/auth.service.ts`
- **CORS Settings**: `backend/src/main.ts`

### Frontend Configuration
- **API Service**: `mobile/lib/core/network/api_service.dart`
- **Auth Provider**: `mobile/lib/features/auth/presentation/providers/auth_provider.dart`
- **Auth Repository**: `mobile/lib/features/auth/data/repositories/auth_repository.dart`
- **Router Configuration**: `mobile/lib/main.dart`

## Common Issues and Solutions

### Issue 1: 401 "Invalid Credentials" Error
**Symptoms**: Login fails with 401 error despite correct credentials

**Possible Causes & Solutions**:
1. **Password Hash Mismatch**
   - Check if bcrypt hash in database matches expected password
   - Solution: Update password hash in database
   
2. **CORS Issues**
   - Check browser console for CORS errors
   - Solution: Verify CORS configuration in `backend/src/main.ts`
   
3. **Backend Not Running**
   - Check if backend server is running on port 3000
   - Solution: Restart backend server

4. **Wrong Request Format**
   - Verify email/password format in Flutter
   - Solution: Add request debugging logs

### Issue 2: JWT Token Not Being Added to Requests
**Symptoms**: Protected endpoints return 401, but interceptor logs show no token

**Possible Causes & Solutions**:
1. **Token Not Saved**
   - Check if login response includes token
   - Solution: Verify `saveToken()` method works
   
2. **Interceptor Logic Error**
   - Check if authentication endpoints are excluded
   - Solution: Update `isAuthEndpoint` logic in interceptor

3. **Storage Issues**
   - Verify flutter_secure_storage works in web environment
   - Solution: Use fallback storage method

### Issue 3: Status Code Mismatch
**Symptoms**: Backend returns 201 but frontend expects 200

**Solution**:
- Update frontend to accept both 200 and 201 status codes
- Common fix: `if (response.statusCode == 200 || response.statusCode == 201)`

### Issue 4: CORS Errors
**Symptoms**: Browser console shows CORS policy errors

**Solution**:
- Add CORS configuration in `backend/src/main.ts`:
```typescript
app.enableCors({
  origin: ['http://localhost:3000', 'http://localhost:5000', 'http://localhost:5001'],
  credentials: true,
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'PATCH', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization'],
});
```

## Testing Authentication

### Backend Testing (curl)
```bash
# Test login
curl -X POST http://localhost:3000/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"testuser@paykey.com","password":"SecurePass123!"}'

# Test protected endpoint
curl -X GET http://localhost:3000/workers \
  -H "Authorization: Bearer <your-jwt-token>"
```

### Frontend Testing (Browser Console)
```javascript
// Check if token is saved
localStorage.getItem('access_token')

// Check network requests
// Open Developer Tools > Network tab
// Look for Authorization headers in requests
```

## Debugging Steps

### 1. Backend Debugging
- Check backend console for authentication errors
- Verify database connection and user existence
- Test authentication endpoints directly with curl
- Check JWT configuration and secret key

### 2. Frontend Debugging
- Enable debugging in `ApiService`:
  - Add request/response logging
  - Add token storage debugging
  - Add interceptor debugging
- Check browser console for errors
- Verify secure storage functionality

### 3. Network Debugging
- Monitor network tab in browser developer tools
- Check request/response headers
- Verify Authorization header format: `Bearer <token>`
- Check response status codes

## Demo User Configuration

### Default Credentials
- **Email**: testuser@paykey.com
- **Password**: SecurePass123!

### Database Password Update
If password needs to be updated:
```bash
cd backend
node fix-demo-user-password.js
```

## Token Management

### JWT Token Structure
```json
{
  "email": "user@example.com",
  "sub": "user-id",
  "tier": "FREE",
  "role": "USER",
  "iat": 1734101136,
  "exp": 1734104736
}
```

### Token Storage
- **Backend**: JWT stored in database (users table)
- **Frontend**: Stored in flutter_secure_storage (web)
- **Expiry**: Configurable (typically 1 hour)

### Token Refresh
- Currently not implemented
- Users must re-login after token expiry
- Future enhancement: Add refresh token mechanism

## Security Best Practices

1. **Password Storage**: Always use bcrypt for password hashing
2. **JWT Secrets**: Use strong, unique JWT secrets in environment variables
3. **Token Expiry**: Set reasonable token expiration times
4. **HTTPS**: Use HTTPS in production
5. **Input Validation**: Validate all authentication inputs
6. **Rate Limiting**: Implement rate limiting for authentication endpoints

## Future Enhancements

1. **Refresh Tokens**: Implement token refresh mechanism
2. **Multi-Factor Authentication**: Add 2FA support
3. **Social Login**: Integrate Google/Apple login
4. **Role-Based Access**: Implement more granular permissions
5. **Session Management**: Add proper session handling