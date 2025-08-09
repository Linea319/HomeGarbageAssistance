#!/data/data/com.termux/files/usr/bin/bash

# Home Garbage Assistance - Termux Starter (Simple)
# Start/Stop backend (Flask) and frontend (Vite) on Termux

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$SCRIPT_DIR"
BACKEND_DIR="$PROJECT_DIR/backend"
FRONTEND_DIR="$PROJECT_DIR/frontend"
LOGS_DIR="$PROJECT_DIR/logs"
PIDS_DIR="$PROJECT_DIR/pids"

mkdir -p "$LOGS_DIR" "$PIDS_DIR"

# ---- printing ----
info()    { echo -e "\e[36m[INFO]\e[0m $1"; }
success() { echo -e "\e[32m[SUCCESS]\e[0m $1"; }
warn()    { echo -e "\e[33m[WARN]\e[0m $1"; }
error()   { echo -e "\e[31m[ERROR]\e[0m $1"; }

# ---- helpers ----
is_running() {
  local pid_file=$1
  [[ -f "$pid_file" ]] || return 1
  local pid
  pid=$(cat "$pid_file" 2>/dev/null || true)
  [[ -n "$pid" ]] && kill -0 "$pid" 2>/dev/null
}

start_backend() {
  if is_running "$PIDS_DIR/backend.pid"; then
    warn "Backend already running (PID: $(cat "$PIDS_DIR/backend.pid"))"
    return 0
  fi

  if [[ ! -d "$BACKEND_DIR" ]]; then
    error "Backend directory not found: $BACKEND_DIR"
    return 1
  fi

  if [[ ! -f "$BACKEND_DIR/venv/bin/activate" ]]; then
    error "Python venv not found. Run ./setup-termux.sh first."
    return 1
  fi

  info "Starting Backend (Flask) ..."
  (
    cd "$BACKEND_DIR"
    source venv/bin/activate
    export FLASK_ENV=production
    export FLASK_APP=main.py
    export PYTHONPATH="$(pwd)"
    nohup python main.py >> "$LOGS_DIR/backend.log" 2>&1 &
    echo $! > "$PIDS_DIR/backend.pid"
  )
  success "Backend started (PID: $(cat "$PIDS_DIR/backend.pid"))"
}

start_frontend() {
  if is_running "$PIDS_DIR/frontend.pid"; then
    warn "Frontend already running (PID: $(cat "$PIDS_DIR/frontend.pid"))"
    return 0
  fi

  if [[ ! -d "$FRONTEND_DIR" ]]; then
    error "Frontend directory not found: $FRONTEND_DIR"
    return 1
  fi

  if [[ ! -f "$FRONTEND_DIR/package.json" ]]; then
    error "package.json not found. Run ./setup-termux.sh first."
    return 1
  fi

  if [[ ! -d "$FRONTEND_DIR/node_modules" ]]; then
    warn "node_modules not found. Run npm install in frontend first."
    return 1
  fi

  info "Starting Frontend (Vite) ..."
  (
    cd "$FRONTEND_DIR"
    nohup npm run dev >> "$LOGS_DIR/frontend.log" 2>&1 &
    echo $! > "$PIDS_DIR/frontend.pid"
  )
  success "Frontend started (PID: $(cat "$PIDS_DIR/frontend.pid"))"
}

stop_service() {
  local name=$1
  local pid_file="$PIDS_DIR/${name}.pid"
  if ! is_running "$pid_file"; then
    warn "$name not running"
    rm -f "$pid_file" 2>/dev/null || true
    return 0
  fi
  local pid=$(cat "$pid_file")
  info "Stopping $name (PID: $pid) ..."
  kill "$pid" 2>/dev/null || true
  for i in {1..10}; do
    if kill -0 "$pid" 2>/dev/null; then sleep 1; else break; fi
  done
  if kill -0 "$pid" 2>/dev/null; then
    warn "$name not stopping, forcing..."
    kill -9 "$pid" 2>/dev/null || true
  fi
  rm -f "$pid_file" 2>/dev/null || true
  success "$name stopped"
}

status() {
  echo "=== Status ==="
  if is_running "$PIDS_DIR/backend.pid"; then
    echo "Backend: RUNNING (PID: $(cat "$PIDS_DIR/backend.pid"))  -> http://localhost:5100"
  else
    echo "Backend: STOPPED"
  fi
  if is_running "$PIDS_DIR/frontend.pid"; then
    echo "Frontend: RUNNING (PID: $(cat "$PIDS_DIR/frontend.pid")) -> http://localhost:5173"
  else
    echo "Frontend: STOPPED"
  fi
}

wakelock() {
  case "$1" in
    on)
      if command -v termux-wake-lock >/dev/null 2>&1; then
        termux-wake-lock && success "Wakelock enabled" || warn "Failed to enable wakelock"
      else
        warn "termux-wake-lock not available (install Termux:API)"
      fi
      ;;
    off)
      if command -v termux-wake-unlock >/dev/null 2>&1; then
        termux-wake-unlock && success "Wakelock disabled" || warn "Failed to disable wakelock"
      else
        warn "termux-wake-unlock not available"
      fi
      ;;
    status)
      if [[ -f "$PIDS_DIR/wakelock.status" ]]; then
        success "Wakelock: enabled"
      else
        warn "Wakelock: unknown (use on/off to control)"
      fi
      ;;
    *)
      echo "Usage: $0 wakelock [on|off|status]"
      ;;
  esac
}

usage() {
  echo "Usage: $0 [start|stop|restart|status|logs <backend|frontend> [lines]|wakelock <on|off|status>|help]"
}

show_logs() {
  local svc=$1
  local lines=${2:-50}
  case "$svc" in
    backend) tail -n "$lines" "$LOGS_DIR/backend.log" 2>/dev/null || echo "No backend log" ;;
    frontend) tail -n "$lines" "$LOGS_DIR/frontend.log" 2>/dev/null || echo "No frontend log" ;;
    *) echo "Usage: $0 logs [backend|frontend] [lines]" ;;
  esac
}

case "$1" in
  start)
    start_backend
    sleep 2
    start_frontend
    status
    ;;
  stop)
    stop_service frontend || true
    stop_service backend || true
    ;;
  restart)
    "$0" stop
    sleep 2
    "$0" start
    ;;
  status)
    status
    ;;
  logs)
    show_logs "$2" "$3"
    ;;
  wakelock)
    wakelock "$2"
    ;;
  help|--help|-h|*)
    usage
    ;;
esac
