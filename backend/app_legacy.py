"""
Flaskアプリケーションのメインファイル
アプリケーションの初期化とルート登録を行う
"""

from flask import Flask, jsonify
from flask_cors import CORS
from app.models import db, GarbageCategory, GarbageType
from app.routes.garbage_routes import garbage_bp
from app.config import config
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
    db.init_app(app)
    
    # ブループリント登録
    from app.routes.admin_routes import admin_bp
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
    
    # データベース初期化（起動と分離）
    # 注意: データベースの初期化は別途 init_database() 関数で行います
    
    return app


def initSampleData():
    """
    サンプルデータをデータベースに追加する
    初回起動時にデモンストレーション用のデータを挿入する
    """
    # 既にデータが存在する場合はスキップ
    if GarbageCategory.query.first():
        return
    
    # サンプルカテゴリデータ
    sampleCategories = [
        {
            'category': '可燃ゴミ',
            'date': 'Monday',
            'method': '専用ゴミ袋に入れて出してください',
            'special_days': json.dumps(['2024-04-11', '2024-04-25']),
            'notion': '生ごみは水気をよく切ってから出してください'
        },
        {
            'category': '不燃ゴミ',
            'date': 'Wednesday',
            'method': '透明または半透明の袋に入れて出してください',
            'special_days': json.dumps([]),
            'notion': '金属類は分別してください'
        },
        {
            'category': 'プラスチック',
            'date': 'Friday',
            'method': 'プラマークの付いた容器のみ',
            'special_days': json.dumps([]),
            'notion': '汚れを落としてから出してください'
        },
        {
            'category': '資源ゴミ',
            'date': 'Saturday',
            'method': '種類別に分けて出してください',
            'special_days': json.dumps([]),
            'notion': 'ペットボトル、缶、ビンを分別'
        }
    ]
    
    # カテゴリデータを挿入
    categoryObjects = []
    for categoryData in sampleCategories:
        category = GarbageCategory(**categoryData)
        db.session.add(category)
        categoryObjects.append(category)
    
    db.session.commit()
    
    # サンプルゴミ種類データ
    sampleGarbageTypes = [
        {'name': '生ごみ', 'category_id': categoryObjects[0].id},
        {'name': '紙くず', 'category_id': categoryObjects[0].id},
        {'name': '木くず', 'category_id': categoryObjects[0].id},
        {'name': '金属類', 'category_id': categoryObjects[1].id},
        {'name': 'ガラス', 'category_id': categoryObjects[1].id},
        {'name': '陶器', 'category_id': categoryObjects[1].id},
        {'name': 'プラスチック容器', 'category_id': categoryObjects[2].id},
        {'name': 'ペットボトル', 'category_id': categoryObjects[3].id},
        {'name': '空き缶', 'category_id': categoryObjects[3].id},
        {'name': 'ビン', 'category_id': categoryObjects[3].id}
    ]
    
    # ゴミ種類データを挿入
    for garbageData in sampleGarbageTypes:
        garbageType = GarbageType(**garbageData)
        db.session.add(garbageType)
    
    db.session.commit()


def initDatabase(json_file: str = None):
    """
    データベースを初期化し、サンプルデータを追加する
    この関数は起動とは別に呼び出される
    Args:
        json_file (str): 初期化に使用するJSONファイルパス（省略時はデフォルトデータ）
    """
    app = createApp()
    with app.app_context():
        print("データベーステーブルを作成中...")
        db.create_all()
        
        if json_file and os.path.exists(json_file):
            print(f"JSONファイルからデータを読み込み中: {json_file}")
            from app.database_manager import DatabaseManager
            result = DatabaseManager.import_from_json(json_file, clear_existing=True)
            print(f"インポート完了: カテゴリ{result['imported_categories']}件, ゴミ種類{result['imported_garbage_types']}件")
        else:
            print("サンプルデータを追加中...")
            initSampleData()
            
        print("データベースの初期化が完了しました！")
        return app


if __name__ == '__main__':
    app = createApp()
    app.run(host='0.0.0.0', port=app.config['PORT_NUMBER'], debug=True)
