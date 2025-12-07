# Login 401 Error - Troubleshooting Guide

## Changes Made

### 1. Fixed Password Hash Issue ✅
- **Problem**: Demo user had plain text password instead of bcrypt hash
- **Solution**: Updated database with proper bcrypt hash for password `testuser123`
- **Script**: `backend/update-demo-password.js`
- **Verification**: Backend test confirms login works (`backend/test-login-endpoint.js`)

### 2. Added Debug Logging ✅
- Added detailed logging in:
  - `mobile/lib/core/network/services/auth_service.dart`
  - `mobile/lib/features/auth/presentation/providers/auth_provider.dart`

## Demo Credentials
- **Email**: `testuser@paykey.com`
- **Password**: `testuser123`

## Verified Working
✅ Backend login endpoint works correctly (tested with Node.js script)
✅ Password hash is correct in database
✅ CORS is properly configured
✅ User exists with correct data

## Next Steps to Diagnose

### Step 1: Check Backend is Running
```bash
# Check if backend container is running
docker ps | grep paykey_backend

# Check backend logs
docker logs paykey_backend --tail 50
```

### Step 2: Run the Mobile App and Check Logs
Run the mobile app and try to login. You should see detailed logs like:
```
🔐 AuthProvider: Starting login for testuser@paykey.com
📍 URL: http://10.0.2.2:3000/auth/login
📡 AuthProvider: Calling loginApi...
```

### Step 3: Check API Connection
The mobile app uses:
- **Android Emulator**: `http://10.0.2.2:3000`
- **iOS Simulator**: `http://localhost:3000`
- **Physical Device**: `http://<YOUR_LOCAL_IP>:3000`

Current configuration in `mobile/lib/core/constants/api_constants.dart`:
```dart
static String get baseUrl {
  if (kIsWeb) {
    return 'http://localhost:3000';
  }
  return 'http://10.0.2.2:3000';
}
```

### Step 4: Common Issues

#### Issue: Backend not accessible from mobile
**Symptoms**: Connection timeout or refused
**Solution**: 
- Ensure backend is running: `docker ps`
- Check backend is on port 3000: `curl http://localhost:3000/auth/login`
- For physical device, get your local IP: `ifconfig` or `ipconfig`

#### Issue: CORS errors
**Symptoms**: Preflight request fails
**Solution**: Already configured in `backend/src/main.ts` to allow all origins in development

#### Issue: Wrong base URL
**Symptoms**: 404 or connection refused
**Solution**: Update `mobile/lib/core/constants/api_constants.dart` with correct IP

### Step 5: Manual Test
Test the backend is accessible from your device/emulator:

#### For Android Emulator:
```bash
# From terminal
curl -X POST http://10.0.2.2:3000/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"testuser@paykey.com","password":"testuser123"}'
```

#### For iOS Simulator:
```bash
curl -X POST http://localhost:3000/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"testuser@paykey.com","password":"testuser123"}'
```

### Step 6: Check Console Output
When you try to login from the mobile app, check:
1. **Flutter Console**: For the detailed logs we added
2. **Backend Console**: `docker logs paykey_backend -f`
3. **Browser DevTools** (if using web): Network tab

## Expected Log Flow

When login works correctly, you should see:
```
📤 Sending login request
📍 URL: http://10.0.2.2:3000/auth/login
📧 Email: testuser@paykey.com
📦 Data: {email: testuser@paykey.com, password: testuser123}
✅ Login response received: 201
🔐 AuthProvider: Starting login for testuser@paykey.com
📡 AuthProvider: Calling loginApi...
📥 AuthProvider: Response received - Status: 201
✅ AuthProvider: Token received, saving...
👤 AuthProvider: User onboarding status: true
🏠 AuthProvider: Navigating to home
```

## Quick Fix Commands

### Restart Backend
```bash
docker-compose restart backend
```

### Check Backend Health
```bash
node backend/test-login-endpoint.js
```

### View Backend Logs
```bash
docker logs paykey_backend -f
```

## Contact Points
If the issue persists, share:
1. Flutter console logs (full output during login attempt)
2. Backend logs (`docker logs paykey_backend --tail 100`)
3. Device/emulator type you're using