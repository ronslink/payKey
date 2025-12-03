#!/bin/bash

echo "==================================="
echo "  PayKey Development Environment"
echo "  CORS: Permissive (All localhost)"
echo "==================================="
echo

# Check if backend is already running
if lsof -ti:3000 > /dev/null 2>&1; then
    echo "Backend appears to be already running on port 3000"
    echo "Check if you want to restart it or continue..."
    echo
    read -p "Do you want to restart the backend? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        pkill -f "npm run start:dev" || true
        sleep 2
    else
        echo "Skipping backend restart..."
        continue_backend=false
    fi
fi

if [ "$continue_backend" != "false" ]; then
    echo "Starting backend server with permissive CORS configuration..."
    echo
    echo "Environment configured:"
    echo "- NODE_ENV: development"
    echo "- PORT: 3000"
    echo "- CORS: Permissive (allows all localhost origins)"
    echo "- Flutter: Works with any random port"
    echo
    
    # Start backend in background
    echo "Starting backend in background..."
    npm run start:dev &
    BACKEND_PID=$!
    sleep 3
    
    echo "Backend started with PID: $BACKEND_PID"
    echo
fi

echo "==================================="
echo "  Starting Flutter Development"
echo "  Target: Chrome (random port)"
echo "  Backend: http://localhost:3000"
echo "==================================="
echo

cd ../mobile

echo "Checking Flutter installation..."
flutter --version

echo
echo "Starting Flutter development server..."
echo "- Will connect to http://localhost:3000"
echo "- CORS allows all localhost origins (random ports supported)"
echo

# Start Flutter without specifying port (random port assignment)
flutter run -d chrome &
FLUTTER_PID=$!

echo
echo "Development environment running!"
echo "- Backend: http://localhost:3000"
echo "- Flutter: Will open on random port"
echo "- CORS: Configured for all localhost traffic"
echo
echo "Press Ctrl+C to stop both services..."
echo

# Wait for user interrupt
trap 'echo "Stopping services..."; kill $BACKEND_PID $FLUTTER_PID 2>/dev/null; exit' INT
wait