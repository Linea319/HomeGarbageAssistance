#!/bin/bash

# Home Garbage Assistance - Full Stack Start Script

echo "=================================================="
echo "    Home Garbage Assistance - Full Stack"
echo "=================================================="

MODE="development"
if [[ "$1" == "prod" ]] || [[ "$1" == "production" ]]; then
    MODE="production"
fi

echo "Environment: $MODE"
echo

# Color codes
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Function to cleanup background processes
cleanup() {
    echo
    print_info "Shutting down servers..."
    if [[ ! -z "$BACKEND_PID" ]]; then
        kill $BACKEND_PID 2>/dev/null
    fi
    if [[ ! -z "$FRONTEND_PID" ]]; then
        kill $FRONTEND_PID 2>/dev/null
    fi
    print_info "Servers stopped"
    exit 0
}

# Set up signal handling
trap cleanup SIGINT SIGTERM

# Start backend
print_info "Starting Backend Server..."
cd "$SCRIPT_DIR/backend"
chmod +x start.sh
./start.sh $MODE &
BACKEND_PID=$!

# Wait for backend to start
sleep 5

# Start frontend
print_info "Starting Frontend Server..."
cd "$SCRIPT_DIR/frontend"
chmod +x start.sh
./start.sh dev &
FRONTEND_PID=$!

# Wait for frontend to start
sleep 3

echo
echo "=================================================="
echo "  Servers are running:"
echo "  - Backend:  http://localhost:5000"
echo "  - Frontend: http://localhost:5173"
echo "=================================================="
echo

print_success "Application is ready!"
print_info "Press Ctrl+C to stop all servers"

# Open browser if available
if command -v xdg-open &> /dev/null; then
    print_info "Opening browser..."
    xdg-open http://localhost:5173 &
elif command -v open &> /dev/null; then
    print_info "Opening browser..."
    open http://localhost:5173 &
fi

# Wait for processes
wait $BACKEND_PID $FRONTEND_PID
