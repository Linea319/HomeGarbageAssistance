#!/usr/bin/env python3
"""
データベース初期化スクリプト
サービスの起動とは独立してデータベースをセットアップする
"""

import sys
import os
import argparse

# プロジェクトルートをパスに追加
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from app import initDatabase

def main():
    parser = argparse.ArgumentParser(description='データベース初期化スクリプト')
    parser.add_argument('--json', '-j', help='初期化に使用するJSONファイルパス')
    parser.add_argument('--export', '-e', help='現在のデータをJSONファイルにエクスポート')
    
    args = parser.parse_args()
    
    print("=== Home Garbage Assistance - Database Initialization ===")
    print()
    
    try:
        if args.export:
            # エクスポートモード
            from app import createApp
            from app.database_manager import DatabaseManager
            
            app = createApp()
            with app.app_context():
                export_data = DatabaseManager.export_to_json(args.export)
                print(f"✅ データベースの内容を {args.export} にエクスポートしました")
                print(f"📊 カテゴリ数: {export_data['metadata']['total_categories']}")
                print(f"📊 ゴミ種類数: {export_data['metadata']['total_garbage_types']}")
        else:
            # 初期化モード
            if args.json:
                if not os.path.exists(args.json):
                    print(f"❌ JSONファイルが見つかりません: {args.json}")
                    sys.exit(1)
                print(f"📁 JSONファイルを使用: {args.json}")
            
            app = initDatabase(args.json)
            print()
            print("✅ データベースの初期化が正常に完了しました！")
            print("💡 サーバーを起動する準備が整いました。")
        
    except Exception as e:
        print(f"❌ 操作中にエラーが発生しました: {str(e)}")
        print("🔧 設定を確認してください。")
        sys.exit(1)

if __name__ == '__main__':
    main()
