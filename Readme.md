# HomeGarbageAssistance

家庭のゴミ回収日を教えてくれるアシスタントWebアプリケーションです。
曜日ごとに回収してくれるゴミの種類を表示し、翌日回収されるゴミの種類を教えてくれます。

## 機能

- 📅 曜日別ゴミ回収情報表示
- 🔍 ゴミ種類の逆検索機能
- 📱 レスポンシブデザイン（スマートフォン対応）
- 🗓️ 今日と翌日のゴミ情報表示
- 📝 特別回収日の管理

## 技術スタック

- **バックエンド**: Python + Flask + SQLAlchemy
- **データベース**: SQLite
- **フロントエンド**: Vue.js 3 + TypeScript + Vite
- **スタイリング**: CSS3 (カスタムスタイル)

## 動作環境

- Windows環境での開発・動作確認
- Android Termux環境での本番運用対応

## プロジェクト構成

```
HomeGarbageAssistance/
├── backend/           # Flaskバックエンド
│   ├── app/
│   │   ├── models/    # データベースモデル
│   │   ├── routes/    # APIルート
│   │   └── config.py  # 設定ファイル
│   ├── app.py         # メインアプリケーション
│   ├── requirements.txt
│   ├── start.bat      # Windows起動スクリプト
│   └── start.sh       # Linux/Mac起動スクリプト
├── frontend/          # Vue.jsフロントエンド
│   ├── src/
│   │   ├── components/ # Vueコンポーネント
│   │   ├── composables/ # Vue Composition API
│   │   └── types/     # TypeScript型定義
│   ├── package.json
│   └── vite.config.ts
├── Specification.md   # 仕様書
├── Rules.md          # 開発ルール
└── README.md         # このファイル
```

## セットアップ手順

### 前提条件
- **Python 3.8+** がインストールされていること
- **Node.js 16+** がインストールされていること
- **Git** がインストールされていること

### リポジトリのクローンとセットアップ

```bash
# リポジトリをクローン
git clone <repository-url>
cd HomeGarbageAssistance

# または新規プロジェクトとして開始
git init
git add .
git commit -m "Initial commit"
```

### バックエンドセットアップ

1. バックエンドディレクトリに移動
```bash
cd backend
```

2. 仮想環境の作成と有効化
```bash
python -m venv venv
# Windows
venv\Scripts\activate
# Linux/Mac
source venv/bin/activate
```

3. 依存関係のインストール
```bash
pip install -r requirements.txt
```

4. アプリケーションの起動
```bash
python app.py
```

または起動スクリプトを使用：
```bash
# Windows
start.bat
# Linux/Mac
chmod +x start.sh
./start.sh
```

### フロントエンドセットアップ

1. フロントエンドディレクトリに移動
```bash
cd frontend
```

2. 依存関係のインストール
```bash
npm install
```

3. 開発サーバーの起動
```bash
npm run dev
```

## 使用方法

### 開発環境での起動

**Option 1: PowerShell（推奨）**
```powershell
# 統合起動（両方同時）
.\start-all.ps1

# 個別起動
.\backend\start.ps1     # バックエンドのみ
.\frontend\start.ps1    # フロントエンドのみ
```

**Option 2: Command Prompt**
```cmd
# 統合起動（両方同時）
start-all.bat

# 個別起動
backend\start.bat      # バックエンドのみ
frontend\start.bat     # フロントエンドのみ
```

### 本番環境での起動
```powershell
.\start-all.ps1 production
```

### アクセス先
- **アプリケーション**: http://localhost:5173
- **バックエンドAPI**: http://localhost:5100
- **APIヘルスチェック**: http://localhost:5100/api/health

## API エンドポイント

- `GET /api/health` - ヘルスチェック
- `GET /api/categories` - 全カテゴリ取得
- `GET /api/categories?day=Monday` - 指定曜日のカテゴリ取得
- `GET /api/categories/today` - 今日のカテゴリ取得
- `GET /api/search?q=生ごみ` - ゴミ種類検索
- `GET /api/categories/{id}` - 指定IDのカテゴリ詳細

## データベース構成

### ゴミカテゴリテーブル
- カテゴリ名、回収曜日、回収方法
- 特別回収日、注意事項

### ゴミ種類テーブル
- ゴミの名前とカテゴリの関連付け

## ライセンス

このプロジェクトはMITライセンスの下で公開されています。
