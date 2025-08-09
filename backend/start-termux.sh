#!/data/data/com.termux/files/usr/bin/bash

# Home Garbage Assistance Backend - Termux (Android) Start Script

set -e  # Exit on any error

echo "=================================================="
echo "  Home Garbage Assistance Backend - Termux"  
echo "=================================================="

# Parse command line arguments
MODE="termux"
if [[ "$1" == "dev" ]] || [[ "$1" == "development" ]]; then
    MODE="development"
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
    print_warning "Some features may not work properly outside Termux"
fi

# Install required packages if not present
print_info "Checking Termux packages..."
if ! command -v python &> /dev/null; then
    print_info "Installing Python..."
    pkg install python -y
fi

if ! command -v git &> /dev/null; then
    print_info "Installing Git..."
    pkg install git -y
fi

# Check Python installation
if ! command -v python &> /dev/null; then
    print_error "Python is not installed"
    echo "Please install Python using: pkg install python"
    exit 1
fi

# Set up storage permissions (optional)
if [ ! -d "$HOME/storage" ]; then
    print_info "Setting up storage access..."
    termux-setup-storage
fi

# Check if virtual environment exists
if [ ! -d "venv" ]; then
    print_info "Creating virtual environment..."
    python -m venv venv
    if [ $? -ne 0 ]; then
        print_error "Failed to create virtual environment"
        print_info "Try: pkg install python-pip"
        exit 1
    fi
    print_success "Virtual environment created"
fi

# Activate virtual environment
print_info "Activating virtual environment..."
source venv/bin/activate
if [ $? -ne 0 ]; then
    print_error "Failed to activate virtual environment"
    exit 1
fi

# Upgrade pip
print_info "Upgrading pip..."
python -m pip install --upgrade pip

# Install dependencies
print_info "Installing dependencies..."
pip install -r requirements.txt
if [ $? -ne 0 ]; then
    print_error "Failed to install dependencies"
    print_info "You may need to install additional packages:"
    print_info "  pkg install libffi-dev openssl-dev"
    exit 1
fi

# Set environment variables for Termux
print_info "Setting environment variables..."
export FLASK_ENV="$MODE"
export FLASK_APP="app.py"
export PYTHONPATH="$(pwd)"

# Termux specific settings
export TMPDIR="$PREFIX/tmp"
export HOME="$HOME"

# Display configuration
echo
echo "=================================================="
echo "Configuration:"
echo "- Environment: $MODE (Termux optimized)"
echo -n "- Python: "
python --version
echo "- Flask App: $FLASK_APP"
echo "- Database: SQLite ($HOME/garbage_assistant.db)"
echo "- Termux Version: ${TERMUX_VERSION:-'Unknown'}"
echo "=================================================="
echo

# Display network information
print_info "Network Information:"
if command -v ifconfig &> /dev/null; then
    LOCAL_IP=$(ifconfig 2>/dev/null | grep -E "inet.*192\.168\.|inet.*10\.|inet.*172\." | head -1 | awk '{print $2}' | cut -d: -f2)
    if [ ! -z "$LOCAL_IP" ]; then
        echo "- Local IP: $LOCAL_IP"
        echo "- Access URL: http://$LOCAL_IP:5100"
    fi
fi
echo "- Localhost: http://localhost:5100"
echo "- All interfaces: http://0.0.0.0:5100"
echo

# Start the application
if [ "$MODE" == "development" ]; then
    print_info "Starting Flask application in DEVELOPMENT mode..."
    print_info "Debug mode is enabled"
else
    print_info "Starting Flask application in TERMUX mode..."
    print_info "Optimized for mobile environment"
fi

print_success "Starting server on all interfaces (0.0.0.0:5000)..."
print_info "Press Ctrl+C to stop the server"
echo

python main.py

print_info "Application stopped"
