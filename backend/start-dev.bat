@echo off
echo ===================================
echo  PayKey Development Environment
echo  CORS Configuration: Enabled
echo ===================================
echo.

REM Check if backend is already running
netstat -an | find ":3000" >nul
if %errorlevel% == 0 (
    echo Backend appears to be already running on port 3000
    echo Check if you want to restart it or continue...
    echo.
    choice /c YN /m "Do you want to restart the backend? (Y/N)"
    if errorlevel 2 goto :mobile_start
    if errorlevel 1 goto :backend_restart
)

:backend_start
echo Starting backend server with development CORS configuration...
echo.

REM Load environment variables from development config
set NODE_ENV=development
set PORT=3000
set DB_HOST=localhost
set DB_PORT=5432
set DB_USERNAME=postgres
set DB_PASSWORD=admin
set DB_NAME=paykey
set JWT_SECRET=dev_secret_key_for_testing_only
set JWT_EXPIRES_IN=24h
set ENABLE_CORS=true
set ENABLE_LOGGING=true

echo Environment configured:
echo - NODE_ENV: %NODE_ENV%
echo - PORT: %PORT%
echo - CORS: Enabled for localhost development
echo.

REM Start backend in background
start "PayKey Backend" cmd /k "cd /d %cd% && npm run start:dev"
timeout /t 3

:backend_restart
echo Backend restarted successfully!
echo.

:mobile_start
echo ===================================
echo  Starting Flutter Development
echo  Target: Chrome
echo  Backend: http://localhost:3000
echo ===================================
echo.

cd ../mobile

echo Checking Flutter installation...
flutter --version

echo.
echo Starting Flutter development server...
echo - This will automatically connect to http://localhost:3000
echo - CORS is configured to allow all localhost traffic
echo.

flutter run -d chrome --web-port=49999 --web-renderer=html

echo.
echo Development environment stopped.
echo Press any key to exit...
pause >nul