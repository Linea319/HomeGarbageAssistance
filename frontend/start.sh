#!/bin/bash

# Home Garbage Assistance Frontend - Linux Start Script

set -e  # Exit on any error

echo "=================================================="
echo "  Home Garbage Assistance Frontend - Linux"
echo "=================================================="

# Parse command line arguments
MODE="development"
if [[ "$1" == "build" ]]; then
    MODE="build"
elif [[ "$1" == "preview" ]]; then
    MODE="preview"
fi

echo "Mode: $MODE"
echo

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check Node.js installation
if ! command -v node &> /dev/null; then
    print_error "Node.js is not installed"
    echo "Please install Node.js using:"
    echo "  curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash -"
    echo "  sudo apt-get install -y nodejs"
    exit 1
fi

# Check npm installation
if ! command -v npm &> /dev/null; then
    print_error "npm is not installed"
    exit 1
fi

# Install dependencies if node_modules doesn't exist
if [ ! -d "node_modules" ]; then
    print_info "Installing dependencies..."
    npm install
    if [ $? -ne 0 ]; then
        print_error "Failed to install dependencies"
        exit 1
    fi
    print_success "Dependencies installed"
fi

# Display configuration
echo
echo "=================================================="
echo "Configuration:"
echo "- Mode: $MODE"
echo -n "- Node.js: "
node --version
echo -n "- npm: "
npm --version
echo "=================================================="
echo

# Execute based on mode
if [ "$MODE" == "build" ]; then
    print_info "Building for production..."
    npm run build
    if [ $? -eq 0 ]; then
        print_success "Build completed! Check ./dist folder"
    else
        print_error "Build failed"
        exit 1
    fi
elif [ "$MODE" == "preview" ]; then
    print_info "Starting preview server..."
    print_info "Preview will be available at: http://localhost:3000"
    npm run preview
else
    print_info "Starting development server..."
    print_info "Frontend will be available at: http://localhost:5173"
    print_info "Backend proxy: http://localhost:5000"
    npm run dev
fi

print_info "Process completed"
