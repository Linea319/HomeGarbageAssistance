"""
Flaskアプリケーションの設定を管理するファイル
環境別の設定とデータベース設定を提供する
"""

import os
from pathlib import Path


class Config:
    """
    基本設定クラス
    共通の設定項目を定義する
    """
    SECRET_KEY = os.environ.get('SECRET_KEY') or 'dev-secret-key-change-in-production'
    SQLALCHEMY_TRACK_MODIFICATIONS = False
    
    # データベースファイルのパス（プロジェクトルートに配置）
    BASE_DIR = Path(__file__).parent.parent.parent
    DATABASE_PATH = BASE_DIR / 'garbage_assistant.db'
    SQLALCHEMY_DATABASE_URI = f'sqlite:///{DATABASE_PATH}'

    #ポート
    PORT_NUMBER = 5100  # デフォルトは5100番ポート

    # CORS 設定（フロントエンドからのアクセス許可）
    ALLOWED_ORIGINS = [
        "http://localhost:3000",
        "http://localhost:5173",
        "http://192.168.1.21:5173",
    ]
    CORS_METHODS = ["GET", "POST", "PUT", "DELETE", "OPTIONS"]
    CORS_ALLOW_HEADERS = ["Content-Type", "Authorization"]
    CORS_RESOURCES = {
        r"/api/*": {
            "origins": ALLOWED_ORIGINS,
            "methods": CORS_METHODS,
            "allow_headers": CORS_ALLOW_HEADERS,
        }
    }


class DevelopmentConfig(Config):
    """
    開発環境用設定クラス
    デバッグモードを有効にし、詳細なログを出力する
    """
    DEBUG = True
    SQLALCHEMY_ECHO = True  # SQLクエリをログに出力


class ProductionConfig(Config):
    """
    本番環境用設定クラス
    セキュリティを重視した設定を行う
    """
    DEBUG = False
    SQLALCHEMY_ECHO = False


class TermuxConfig(Config):
    """
    Termux環境用設定クラス
    Android Termux環境での動作に最適化した設定
    """
    DEBUG = False
    SQLALCHEMY_ECHO = False
    
    # Termux環境では$HOME配下にDBファイルを配置
    TERMUX_HOME = os.environ.get('HOME', '/data/data/com.termux/files/home')
    DATABASE_PATH = Path(TERMUX_HOME) / 'garbage_assistant.db'
    SQLALCHEMY_DATABASE_URI = f'sqlite:///{DATABASE_PATH}'


# 環境変数から設定を選択
config = {
    'development': DevelopmentConfig,
    'production': ProductionConfig,
    'termux': TermuxConfig,
    'default': DevelopmentConfig
}
