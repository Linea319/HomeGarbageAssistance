#!/data/data/com.termux/files/usr/bin/bash

# Home Garbage Assistance - Termux Setup Script (Simple)
# This prepares Termux with required packages and project dependencies

set -e

# ---- printing ----
color(){ echo -e "\e[$1m$2\e[0m"; }
info(){ color "36" "$1"; }
success(){ color "32" "$1"; }
warn(){ color "33" "$1"; }
error(){ color "31" "$1"; }
header(){ color "35" "$1"; }

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$SCRIPT_DIR"
BACKEND_DIR="$PROJECT_DIR/backend"
FRONTEND_DIR="$PROJECT_DIR/frontend"

header "🏗  Home Garbage Assistance - Termux セットアップ"
header "=================================================="
echo ""

# Termux environment check
if [ -z "$PREFIX" ]; then
  warn "Termux環境ではない可能性があります。このスクリプトはTermux想定です。"
  echo ""
fi

# Update packages
info "📦 パッケージリストを更新中..."
pkg update -y

# Install base packages
info "📦 必要なパッケージをインストール中..."
pkg install -y python python-pip nodejs git

# Optional: Termux:API (for wakelock etc.)
if ! command -v termux-wake-lock >/dev/null 2>&1; then
  warn "termux-api が未インストール。wakelockを使う場合は 'pkg install termux-api' を実行してください。"
fi

# ---- Backend setup ----
if [ -d "$BACKEND_DIR" ]; then
  info "🐍 バックエンド環境をセットアップ中..."
  cd "$BACKEND_DIR"
  if [ ! -d "venv" ]; then
    info "Python仮想環境を作成..."
    python -m venv venv
    success "venv 作成"
  fi
  # Activate and install deps
  # shellcheck disable=SC1091
  source venv/bin/activate
  python -m pip install --upgrade pip
  if [ -f "requirements.txt" ]; then
    pip install -r requirements.txt
    success "バックエンド依存関係のインストール完了"
  else
    warn "requirements.txt が見つかりません。必要に応じて作成してください。"
  fi
  deactivate
else
  warn "バックエンドディレクトリが見つかりません: $BACKEND_DIR"
fi

# ---- Frontend setup ----
if [ -d "$FRONTEND_DIR" ]; then
  info "📱 フロントエンド環境をセットアップ中..."
  cd "$FRONTEND_DIR"
  if [ -f "package.json" ]; then
    npm install --no-audit --no-fund
    # esbuild ヘルスチェック
    if ! node -e "require('esbuild'); console.log('esbuild ok')" >/dev/null 2>&1; then
      warn "esbuild がこの端末で動作しません。ソースから再ビルドします。"
      pkg install -y golang
      npm rebuild esbuild --build-from-source || {
        warn "再ビルドに失敗。esbuildを0.19系に固定して再試行します。"
        npm i -D esbuild@0.19.12 --force
      }
    fi
    success "フロントエンド依存関係のインストール完了"
  else
    warn "package.json が見つかりません。フロントエンドは未初期化の可能性があります。"
  fi
else
  warn "フロントエンドディレクトリが見つかりません: $FRONTEND_DIR"
fi

# ---- Directories & permissions ----
cd "$PROJECT_DIR"
mkdir -p logs pids
success "logs / pids ディレクトリを作成"

if [ -f "$PROJECT_DIR/start-termux.sh" ]; then
  chmod +x "$PROJECT_DIR/start-termux.sh"
  success "start-termux.sh に実行権限を付与"
else
  warn "start-termux.sh が見つかりません。先に作成するか取得してください。"
fi

# ---- Summary ----
echo ""
success "✅ Termuxセットアップが完了しました"
info "次のコマンドで起動できます:"
info "  ./start-termux.sh start"

echo ""
info "便利なコマンド:" 
info "  ./start-termux.sh status          # 状態確認"
info "  ./start-termux.sh logs backend 50  # バックエンドログ"
info "  ./start-termux.sh logs frontend 50 # フロントエンドログ"
info "  ./start-termux.sh wakelock on      # 省電力無効化 (Termux:API)"
