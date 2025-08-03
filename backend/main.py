#!/usr/bin/env python3
"""
Flaskアプリケーションのメインエントリーポイント
アプリケーションの起動を行う
"""

from app import createApp, initDatabase
import os
import sys


def main():
    """
    メイン関数：アプリケーションを起動する
    """
    # 環境変数からポートとホストを取得
    port = int(os.environ.get('PORT', 5100))
    host = os.environ.get('HOST', '0.0.0.0')
    debug = os.environ.get('FLASK_DEBUG', 'False').lower() == 'true'
    
    # Flaskアプリケーションを作成
    app = createApp()
    
    # アプリケーションコンテキスト内でデータベースを初期化
    with app.app_context():
        try:
            # データベースの初期化
            initDatabase()
        except Exception as e:
            print(f"⚠️  データベース初期化中にエラーが発生しましたが、アプリケーションを続行します: {str(e)}")
    
    print(f"🚀 HomeGarbageAssistance API を起動中...")
    print(f"   URL: http://{host}:{port}")
    print(f"   デバッグモード: {debug}")
    print(f"   終了するには Ctrl+C を押してください")
    
    try:
        # Flaskアプリケーションを起動
        app.run(
            host=host,
            port=port,
            debug=debug,
            use_reloader=debug
        )
    except KeyboardInterrupt:
        print("\n👋 アプリケーションを終了します...")
    except Exception as e:
        print(f"❌ アプリケーション起動中にエラーが発生しました: {str(e)}")
        sys.exit(1)


if __name__ == '__main__':
    main()
