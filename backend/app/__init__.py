"""
Flaskアプリケーションパッケージ
アプリケーションの初期化とルート登録を行う
"""

from flask import Flask, jsonify
from flask_cors import CORS
import os
import json


def createApp(configName: str = None) -> Flask:
    """
    Flaskアプリケーションを作成し、初期化する
    Args:
        configName (str): 使用する設定名 ('development', 'production', 'termux')
    Returns:
        Flask: 初期化されたFlaskアプリケーション
    """
    app = Flask(__name__)
    
    # 設定の読み込み
    from .config import config
    if configName is None:
        configName = os.environ.get('FLASK_ENV', 'development')
    
    app.config.from_object(config.get(configName, config['default']))
    
    # CORS設定（フロントエンドからのアクセス許可）
    CORS(app, resources={
        r"/api/*": {
            "origins": ["http://localhost:3000", "http://localhost:5173", "http://127.0.0.1:*"],
            "methods": ["GET", "POST", "PUT", "DELETE"],
            "allow_headers": ["Content-Type", "Authorization"]
        }
    })
    
    # データベース初期化
    from .models import db
    db.init_app(app)
    
    # ブループリント登録
    from .routes.garbage_routes import garbage_bp
    from .routes.admin_routes import admin_bp
    app.register_blueprint(garbage_bp)
    app.register_blueprint(admin_bp)
    
    # ヘルスチェックエンドポイント
    @app.route('/api/health', methods=['GET'])
    def healthCheck():
        """
        アプリケーションの稼働状況を確認するエンドポイント
        Returns:
            JSON: アプリケーションのステータス情報
        """
        return jsonify({
            'status': 'healthy',
            'message': 'HomeGarbageAssistance API is running',
            'config': configName
        })
    
    return app


def initSampleData():
    """
    サンプルデータをデータベースに追加する
    初回起動時にデモンストレーション用のデータを挿入する
    """
    from .models import db, GarbageCategory, GarbageType
    
    # 既にデータが存在する場合はスキップ
    if GarbageCategory.query.first():
        print("📋 既存のデータが見つかりました。サンプルデータの追加をスキップします。")
        return
    
    # サンプルカテゴリデータ
    sample_categories = [
        {
            'category': '可燃ゴミ',
            'date': json.dumps(['Tuesday', 'Friday']),
            'method': '指定のゴミ袋に入れて出してください',
            'notion': '生ごみは水気をよく切ってから出してください',
            'special_days': json.dumps([]),
            'garbage_types': ['生ごみ', '紙くず', 'プラスチック']
        },
        {
            'category': '不燃ゴミ',
            'date': json.dumps(['Wednesday']),
            'method': '透明な袋に入れて出してください',
            'notion': '金属類は分別してください',
            'special_days': json.dumps([]),
            'garbage_types': ['缶', 'ビン', '金属類']
        }
    ]
    
    print("📦 サンプルデータを追加中...")
    
    for cat_data in sample_categories:
        # カテゴリを作成
        category = GarbageCategory(
            category=cat_data['category'],
            date=cat_data['date'],
            method=cat_data['method'],
            notion=cat_data['notion'],
            special_days=cat_data['special_days']
        )
        
        db.session.add(category)
        db.session.flush()  # IDを取得するため
        
        # ゴミ種類を追加
        for garbage_name in cat_data['garbage_types']:
            garbage_type = GarbageType(
                name=garbage_name,
                category_id=category.id
            )
            db.session.add(garbage_type)
    
    db.session.commit()
    print("✅ サンプルデータの追加が完了しました！")


def initDatabase(json_file: str = None):
    """
    データベースの初期化を行う
    Args:
        json_file (str): 初期データとして読み込むJSONファイルのパス
    """
    from .models import db
    
    print("🔧 データベースを初期化中...")
    
    # テーブルを作成
    db.create_all()
    print("📊 データベーステーブルを作成しました")
    
    if json_file and os.path.exists(json_file):
        print(f"📥 JSONファイル '{json_file}' からデータを読み込み中...")
        try:
            from .database_manager import DatabaseManager
            result = DatabaseManager.import_from_json(json_file, clear_existing=True)
            print(f"✅ JSONデータのインポートが完了しました: {result}")
        except Exception as e:
            print(f"❌ JSONインポート中にエラーが発生しました: {str(e)}")
            # エラーが発生してもサンプルデータで続行
            initSampleData()
    else:
        # JSONファイルが指定されていない場合はサンプルデータを追加
        initSampleData()
    
    print("🎉 データベースの初期化が完了しました！")


# パッケージからエクスポートする関数を定義
__all__ = ['createApp', 'initSampleData', 'initDatabase']
