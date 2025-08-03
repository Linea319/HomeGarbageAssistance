#!/data/data/com.termux/files/usr/bin/bash

# Home Garbage Assistance Frontend - Termux (Android) Start Script

set -e  # Exit on any error

echo "=================================================="
echo "  Home Garbage Assistance Frontend - Termux"
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

# Check if running in Termux
if [ -z "$TERMUX_VERSION" ]; then
    print_warning "This script is designed for Termux environment"
fi

# Install required packages if not present
print_info "Checking Termux packages..."
if ! command -v node &> /dev/null; then
    print_info "Installing Node.js..."
    pkg install nodejs -y
fi

if ! command -v git &> /dev/null; then
    print_info "Installing Git..."
    pkg install git -y
fi

# Check Node.js installation
if ! command -v node &> /dev/null; then
    print_error "Node.js is not installed"
    echo "Please install Node.js using: pkg install nodejs"
    exit 1
fi

# Check npm installation
if ! command -v npm &> /dev/null; then
    print_error "npm is not available"
    print_info "Try reinstalling nodejs: pkg install nodejs"
    exit 1
fi

# Set up Termux specific environment
export TMPDIR="$PREFIX/tmp"
export NODE_OPTIONS="--max-old-space-size=2048"

# Install dependencies if node_modules doesn't exist
if [ ! -d "node_modules" ]; then
    print_info "Installing dependencies..."
    print_warning "This may take a while on mobile devices..."
    npm install --no-audit --no-fund
    if [ $? -ne 0 ]; then
        print_error "Failed to install dependencies"
        print_info "Try: pkg install python make"
        exit 1
    fi
    print_success "Dependencies installed"
fi

# Display configuration
echo
echo "=================================================="
echo "Configuration:"
echo "- Mode: $MODE (Termux optimized)"
echo -n "- Node.js: "
node --version
echo -n "- npm: "
npm --version
echo "- Termux Version: ${TERMUX_VERSION:-'Unknown'}"
echo "- Memory limit: 2GB (NODE_OPTIONS)"
echo "=================================================="
echo

# Display network information
print_info "Network Information:"
if command -v ifconfig &> /dev/null; then
    LOCAL_IP=$(ifconfig 2>/dev/null | grep -E "inet.*192\.168\.|inet.*10\.|inet.*172\." | head -1 | awk '{print $2}' | cut -d: -f2)
    if [ ! -z "$LOCAL_IP" ]; then
        echo "- Local IP: $LOCAL_IP"
    fi
fi
echo

# Execute based on mode
if [ "$MODE" == "build" ]; then
    print_info "Building for production..."
    print_warning "Build process may be slow on mobile devices"
    npm run build
    if [ $? -eq 0 ]; then
        print_success "Build completed! Check ./dist folder"
    else
        print_error "Build failed"
        exit 1
    fi
elif [ "$MODE" == "preview" ]; then
    print_info "Starting preview server..."
    if [ ! -z "$LOCAL_IP" ]; then
        echo "- Preview URL: http://$LOCAL_IP:3000"
    fi
    echo "- Localhost: http://localhost:3000"
    npm run preview
else
    print_info "Starting development server..."
    print_info "This may take longer on mobile devices..."
    if [ ! -z "$LOCAL_IP" ]; then
        echo "- Frontend URL: http://$LOCAL_IP:5173"
    fi
    echo "- Localhost: http://localhost:5173"
    echo "- Backend proxy: http://localhost:5000"
    print_warning "Press Ctrl+C to stop the server"
    echo
    npm run dev
fi

print_info "Process completed"
