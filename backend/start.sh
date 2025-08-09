#!/bin/bash

# Home Garbage Assistance Backend - Linux/Ubuntu Start Script

set -e  # Exit on any error

echo "=================================================="
echo "  Home Garbage Assistance Backend - Linux"
echo "=================================================="

# Parse command line arguments
MODE="development"
if [[ "$1" == "prod" ]] || [[ "$1" == "production" ]]; then
    MODE="production"
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

# Check Python installation
if ! command -v python3 &> /dev/null; then
    print_error "Python3 is not installed"
    echo "Please install Python 3.8+ using:"
    echo "  sudo apt update && sudo apt install python3 python3-pip python3-venv"
    exit 1
fi

# Check if virtual environment exists
if [ ! -d "venv" ]; then
    print_info "Creating virtual environment..."
    python3 -m venv venv
    if [ $? -ne 0 ]; then
        print_error "Failed to create virtual environment"
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
    exit 1
fi

# Set environment variables
print_info "Setting environment variables..."
export FLASK_ENV="$MODE"
export FLASK_APP="main.py"
export PYTHONPATH="$(pwd)"

# Display configuration
echo
echo "=================================================="
echo "Configuration:"
echo "- Environment: $MODE"
echo -n "- Python: "
python --version
echo "- Flask App: $FLASK_APP"
echo "- Database: SQLite (garbage_assistant.db)"
echo "=================================================="
echo

# Start the application
if [ "$MODE" == "production" ]; then
    print_info "Starting Flask application in PRODUCTION mode..."
    print_warning "Debug mode is disabled"
    python main.py
else
    print_info "Starting Flask application in DEVELOPMENT mode..."
    print_info "Debug mode is enabled"
    print_info "API will be available at: http://localhost:5100"
    python main.py
fi

print_info "Application stopped"
