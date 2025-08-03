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
│   ├── init_db.py     # データベース初期化スクリプト
│   ├── manage_db.py   # データベース管理スクリプト
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

### 1. 初回セットアップ

**ステップ1: リポジトリのクローン**
```bash
git clone https://github.com/your-username/HomeGarbageAssistance.git
cd HomeGarbageAssistance
```

**ステップ2: バックエンドのセットアップ**
```bash
cd backend

# 仮想環境の作成と有効化（推奨）
python -m venv venv
# Windows
venv\Scripts\activate
# Linux/Mac
source venv/bin/activate

# 依存関係のインストール
pip install -r requirements.txt

# データベースの初期化
python init_db.py
```

**ステップ3: フロントエンドのセットアップ**
```bash
cd ../frontend

# 依存関係のインストール
npm install
```

**ステップ4: アプリケーションの起動**
```bash
cd ..

# 統合起動（推奨）
.\start-all.ps1    # PowerShell
# または
start-all.bat      # Command Prompt
```

### 2. 日常的な使用手順

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

### 2. 日常的な使用

```bash
# アプリケーション開始
.\start-all.ps1 start

# アプリケーション停止
.\start-all.ps1 stop

# 状態確認
.\start-all.ps1 status
```

### 3. 個別セットアップ（上級者向け）

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

## データベース管理

このアプリケーションではSQLiteデータベースを使用しており、サービス起動とは独立してデータベースを管理できます。

### データベースの初期化

**初回セットアップ時のみ実行**

```bash
cd backend

# 方法1: シンプルな初期化（推奨）
python init_db.py

# 方法2: 管理スクリプトを使用
python manage_db.py seed    # テーブル作成 + サンプルデータ
```

### データベース管理コマンド

```bash
cd backend

# データベースの状態確認
python manage_db.py status

# テーブルのみ作成（データは追加しない）
python manage_db.py init

# データベースを完全リセット
python manage_db.py reset

# 新しいカテゴリを追加
python manage_db.py add-category --name "電池類" --day "Friday" --method "回収ボックスへ" --notion "種類別に分別"
```

### データベースの状態確認

データベース管理スクリプトを実行すると以下の情報が表示されます：

```
📊 データベース状態:
------------------------------
カテゴリ数: 7
ゴミ種類数: 28

📋 登録されているカテゴリ:
  - 可燃ゴミ (Monday) - 3種類
  - 不燃ゴミ (Wednesday) - 3種類
  - プラスチック (Friday) - 4種類
  - 資源ゴミ (Saturday) - 3種類
```

### サンプルデータ

初期化時に以下のサンプルデータが登録されます：

#### ゴミカテゴリ
- **可燃ゴミ** (月曜日) - 生ごみ、紙くず、木くず
- **不燃ゴミ** (水曜日) - 金属類、ガラス、陶器
- **プラスチック** (金曜日) - プラスチック容器
- **資源ゴミ** (土曜日) - ペットボトル、空き缶、ビン

### データベースファイルの場所

- **開発環境**: `backend/instance/garbage_assistant.db`
- **本番環境**: 設定で指定されたパス

⚠️ **注意**: データベースファイルを削除した場合は、再度初期化が必要です。

### トラブルシューティング

#### データベースエラーが発生した場合

1. **テーブルが存在しない**
   ```bash
   python manage_db.py init
   ```

2. **データが重複している**
   ```bash
   python manage_db.py reset
   python manage_db.py seed
   ```

3. **権限エラー**
   - データベースファイルの権限を確認
   - 別のプロセスがファイルを使用していないか確認

## 使用方法

### サービス管理（推奨）

統合サービス管理スクリプトを使用すると、バックエンドとフロントエンドを一括で管理できます。

**Windows PowerShell:**
```powershell
# サービス開始
.\start-all.ps1 start              # 開発モード
.\start-all.ps1 start production   # 本番モード

# サービス停止
.\start-all.ps1 stop

# サービス再起動
.\start-all.ps1 restart

# サービス状態確認
.\start-all.ps1 status

# ヘルプ表示
.\start-all.ps1 help
```

**Windows Command Prompt:**
```cmd
# サービス開始
start-all.bat start              # 開発モード
start-all.bat start production   # 本番モード

# サービス停止
start-all.bat stop

# その他のコマンドも同様
```

**Linux/Mac bash:**
```bash
# サービス開始
./start-all.sh start              # 開発モード
./start-all.sh start production   # 本番モード

# サービス停止
./start-all.sh stop

# その他のコマンドも同様
```

### 開発環境での起動（従来方法）

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

### データベーステーブル構造

#### GarbageCategory（ゴミカテゴリ）
| カラム名 | データ型 | 説明 |
|---------|---------|------|
| id | INTEGER | 主キー |
| category | STRING(100) | カテゴリ名（例：可燃ゴミ） |
| date | STRING(20) | 回収曜日（例：Monday） |
| method | STRING(200) | 回収方法 |
| special_days | TEXT | 特別回収日（JSON形式） |
| notion | TEXT | 注意事項 |
| created_at | DATETIME | 作成日時 |
| updated_at | DATETIME | 更新日時 |

#### GarbageType（ゴミ種類）
| カラム名 | データ型 | 説明 |
|---------|---------|------|
| id | INTEGER | 主キー |
| name | STRING(100) | ゴミの名前（例：生ごみ） |
| category_id | INTEGER | カテゴリID（外部キー） |
| created_at | DATETIME | 作成日時 |
| updated_at | DATETIME | 更新日時 |

### データ追加の例

#### プログラムから追加
```python
from app.models import db, GarbageCategory, GarbageType
import json

# 新カテゴリの追加
category = GarbageCategory(
    category='危険物',
    date='Monday',
    method='市役所の専用回収ボックスへ',
    special_days=json.dumps(['2024-12-29']),
    notion='取り扱い注意'
)
db.session.add(category)
db.session.commit()

# 新ゴミ種類の追加
garbage_type = GarbageType(
    name='スプレー缶',
    category_id=category.id
)
db.session.add(garbage_type)
db.session.commit()
```

#### 管理スクリプトから追加
```bash
# 新しいカテゴリを追加
python manage_db.py add-category \
  --name "有害ごみ" \
  --day "Sunday" \
  --method "月1回の回収日に出す" \
  --notion "蛍光灯、電池類など"
```

### データベースファイルの管理

- **場所**: `backend/instance/garbage_assistant.db`
- **形式**: SQLite3形式
- **バックアップ**: データベースファイルをコピーして保存
- **移行**: ファイルを別環境にコピーして使用可能

## ライセンス

このプロジェクトはMITライセンスの下で公開されています。
