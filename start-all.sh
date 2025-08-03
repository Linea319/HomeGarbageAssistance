#!/bin/bash

# Home Garbage Assistance - Full Stack Service Manager

# Parse command line arguments
COMMAND="${1:-start}"
MODE="${2:-development}"

# Validate parameters
case "$COMMAND" in
    start|stop|restart|status|help) ;;
    *) 
        echo "[ERROR] Unknown command: $COMMAND"
        echo "Run './start-all.sh help' for usage information"
        exit 1
        ;;
esac

# Handle mode aliases
if [[ "$MODE" == "prod" ]]; then
    MODE="production"
fi

# Show help
if [[ "$COMMAND" == "help" ]]; then
    echo "Home Garbage Assistance - Service Manager"
    echo "========================================"
    echo
    echo "Usage: ./start-all.sh [COMMAND] [MODE]"
    echo
    echo "Commands:"
    echo "  start      Start both backend and frontend servers (default)"
    echo "  stop       Stop all running servers"
    echo "  restart    Restart all servers"
    echo "  status     Check server status"
    echo "  help       Show this help message"
    echo
    echo "Modes (only for start/restart):"
    echo "  development    Development mode (default)"
    echo "  production     Production mode"
    echo "  prod           Production mode (short form)"
    echo
    echo "Examples:"
    echo "  ./start-all.sh                      # Start in development mode"
    echo "  ./start-all.sh start production     # Start in production mode"
    echo "  ./start-all.sh stop                 # Stop all servers"
    echo "  ./start-all.sh restart              # Restart in development mode"
    echo "  ./start-all.sh status               # Check server status"
    echo
    exit 0
fi

echo "=================================================="
echo "    Home Garbage Assistance - Service Manager"
echo "=================================================="

# Color codes
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Port configuration
BACKEND_PORT=5100
FRONTEND_PORT=5173

# PID file paths
BACKEND_PID_FILE="$SCRIPT_DIR/.backend.pid"
FRONTEND_PID_FILE="$SCRIPT_DIR/.frontend.pid"

# Function to check if port is in use
is_port_in_use() {
    local port=$1
    if command -v lsof &> /dev/null; then
        lsof -i :$port &> /dev/null
    elif command -v netstat &> /dev/null; then
        netstat -tuln | grep -q ":$port "
    else
        # Fallback: try to bind to the port
        (echo >/dev/tcp/localhost/$port) &>/dev/null
    fi
}

# Function to get process PID by port
get_pid_by_port() {
    local port=$1
    if command -v lsof &> /dev/null; then
        lsof -ti :$port 2>/dev/null | head -1
    elif command -v netstat &> /dev/null && command -v ps &> /dev/null; then
        local line=$(netstat -tuln -p 2>/dev/null | grep ":$port ")
        if [[ -n "$line" ]]; then
            echo "$line" | awk '{print $7}' | cut -d'/' -f1
        fi
    fi
}

# Function to check server status
check_status() {
    echo "Service Status:"
    echo "==============="
    
    # Check backend
    echo -n "Backend (port $BACKEND_PORT):  "
    if is_port_in_use $BACKEND_PORT; then
        local backend_pid=$(get_pid_by_port $BACKEND_PORT)
        echo -e "${GREEN}RUNNING${NC} (PID: $backend_pid)"
    else
        echo -e "${RED}STOPPED${NC}"
    fi
    
    # Check frontend
    echo -n "Frontend (port $FRONTEND_PORT): "
    if is_port_in_use $FRONTEND_PORT; then
        local frontend_pid=$(get_pid_by_port $FRONTEND_PORT)
        echo -e "${GREEN}RUNNING${NC} (PID: $frontend_pid)"
    else
        echo -e "${RED}STOPPED${NC}"
    fi
    
    echo
}

# Function to stop services
stop_services() {
    print_info "Stopping services..."
    
    local stopped_any=false
    
    # Stop backend
    if is_port_in_use $BACKEND_PORT; then
        local backend_pid=$(get_pid_by_port $BACKEND_PORT)
        if [[ -n "$backend_pid" ]]; then
            print_info "Stopping backend (PID: $backend_pid)..."
            kill $backend_pid 2>/dev/null
            sleep 2
            if kill -0 $backend_pid 2>/dev/null; then
                print_warning "Backend still running, forcing termination..."
                kill -9 $backend_pid 2>/dev/null
            fi
            stopped_any=true
        fi
    fi
    
    # Stop frontend
    if is_port_in_use $FRONTEND_PORT; then
        local frontend_pid=$(get_pid_by_port $FRONTEND_PORT)
        if [[ -n "$frontend_pid" ]]; then
            print_info "Stopping frontend (PID: $frontend_pid)..."
            kill $frontend_pid 2>/dev/null
            sleep 2
            if kill -0 $frontend_pid 2>/dev/null; then
                print_warning "Frontend still running, forcing termination..."
                kill -9 $frontend_pid 2>/dev/null
            fi
            stopped_any=true
        fi
    fi
    
    # Clean up PID files
    rm -f "$BACKEND_PID_FILE" "$FRONTEND_PID_FILE" 2>/dev/null
    
    if [[ "$stopped_any" == true ]]; then
        print_success "Services stopped successfully"
    else
        print_warning "No services were running"
    fi
}

# Function to start services
start_services() {
    echo "Command: $COMMAND"
    echo "Environment: $MODE"
    echo
    
    # Check if services are already running
    local backend_running=false
    local frontend_running=false
    
    if is_port_in_use $BACKEND_PORT; then
        backend_running=true
        print_warning "Backend is already running on port $BACKEND_PORT"
    fi
    
    if is_port_in_use $FRONTEND_PORT; then
        frontend_running=true
        print_warning "Frontend is already running on port $FRONTEND_PORT"
    fi
    
    if [[ "$backend_running" == true && "$frontend_running" == true ]]; then
        print_warning "Both services are already running!"
        check_status
        return 1
    fi
    
    # Function to cleanup background processes on exit
    cleanup() {
        echo
        print_info "Shutting down servers..."
        if [[ ! -z "$BACKEND_PID" ]]; then
            kill $BACKEND_PID 2>/dev/null
        fi
        if [[ ! -z "$FRONTEND_PID" ]]; then
            kill $FRONTEND_PID 2>/dev/null
        fi
        rm -f "$BACKEND_PID_FILE" "$FRONTEND_PID_FILE" 2>/dev/null
        print_info "Servers stopped"
        exit 0
    }
    
    # Set up signal handling
    trap cleanup SIGINT SIGTERM
    
    # Start backend if not running
    if [[ "$backend_running" == false ]]; then
        print_info "Starting Backend Server..."
        cd "$SCRIPT_DIR/backend"
        chmod +x start.sh
        ./start.sh $MODE &
        BACKEND_PID=$!
        echo $BACKEND_PID > "$BACKEND_PID_FILE"
        
        # Wait for backend to start
        sleep 5
        
        if ! is_port_in_use $BACKEND_PORT; then
            print_error "Failed to start backend server"
            return 1
        fi
        print_success "Backend server started (PID: $BACKEND_PID)"
    fi
    
    # Start frontend if not running
    if [[ "$frontend_running" == false ]]; then
        print_info "Starting Frontend Server..."
        cd "$SCRIPT_DIR/frontend"
        chmod +x start.sh
        ./start.sh dev &
        FRONTEND_PID=$!
        echo $FRONTEND_PID > "$FRONTEND_PID_FILE"
        
        # Wait for frontend to start
        sleep 3
        
        if ! is_port_in_use $FRONTEND_PORT; then
            print_error "Failed to start frontend server"
            return 1
        fi
        print_success "Frontend server started (PID: $FRONTEND_PID)"
    fi
    
    echo
    echo "=================================================="
    echo "  Servers are running:"
    echo "  - Backend:  http://localhost:$BACKEND_PORT"
    echo "  - Frontend: http://localhost:$FRONTEND_PORT"
    echo "=================================================="
    echo
    
    print_success "Application is ready!"
    print_info "Press Ctrl+C to stop all servers"
    
    # Open browser if available
    if command -v xdg-open &> /dev/null; then
        print_info "Opening browser..."
        xdg-open http://localhost:$FRONTEND_PORT &
    elif command -v open &> /dev/null; then
        print_info "Opening browser..."
        open http://localhost:$FRONTEND_PORT &
    fi
    
# Main command execution
case "$COMMAND" in
    start)
        start_services
        ;;
    stop)
        stop_services
        ;;
    restart)
        print_info "Restarting services..."
        stop_services
        sleep 2
        start_services
        ;;
    status)
        check_status
        ;;
esac
