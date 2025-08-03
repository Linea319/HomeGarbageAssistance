#!/usr/bin/env python3
"""
データベース管理スクリプト
データベースの作成、リセット、データ追加などの管理操作を提供
"""

import sys
import os
import json
import argparse

# プロジェクトルートをパスに追加
current_dir = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, current_dir)

# app パッケージから createApp をインポート
from app import createApp, initDatabase
from app.models import db, GarbageCategory, GarbageType
from app.database_manager import DatabaseManager

def init_database():
    """データベースを初期化"""
    app = createApp()
    with app.app_context():
        print("📊 データベーステーブルを作成中...")
        db.create_all()
        print("✅ テーブル作成完了")
        return app

def seed_database():
    """サンプルデータを追加"""
    app = createApp()
    with app.app_context():
        # 既存データチェック
        if GarbageCategory.query.first():
            print("⚠️  既存データが見つかりました")
            response = input("既存データを削除して再作成しますか？ (y/N): ")
            if response.lower() != 'y':
                print("❌ 操作をキャンセルしました")
                return
            
            print("🗑️  既存データを削除中...")
            db.session.query(GarbageType).delete()
            db.session.query(GarbageCategory).delete()
            db.session.commit()
        
        print("🌱 サンプルデータを追加中...")
        from app import initSampleData
        initSampleData()
        print("✅ サンプルデータ追加完了")


def import_json_file(json_path):
    """JSONファイルからデータをインポート"""
    if not os.path.exists(json_path):
        print(f"❌ ファイルが見つかりません: {json_path}")
        return False
    
    app = createApp()
    with app.app_context():
        try:
            print(f"📥 JSONファイル '{json_path}' からデータをインポート中...")
            result = DatabaseManager.import_from_json(json_path, clear_existing=True)
            
            print(f"✅ インポートが完了しました！")
            print(f"   インポートされたカテゴリ数: {result.get('imported_categories', 0)}")
            print(f"   インポートされたゴミ種類数: {result.get('imported_garbage_types', 0)}")
            
            return True
            
        except Exception as e:
            print(f"❌ インポート中にエラーが発生しました: {str(e)}")
            import traceback
            traceback.print_exc()
            return False

def reset_database():
    """データベースをリセット"""
    app = createApp()
    with app.app_context():
        print("🔄 データベースをリセット中...")
        db.drop_all()
        db.create_all()
        print("✅ データベースリセット完了")

def show_status():
    """データベースの状態を表示"""
    app = createApp()
    with app.app_context():
        print("📊 データベース状態:")
        print("-" * 30)
        
        categories = GarbageCategory.query.all()
        garbage_types = GarbageType.query.all()
        
        print(f"カテゴリ数: {len(categories)}")
        print(f"ゴミ種類数: {len(garbage_types)}")
        
        if categories:
            print("\n📋 登録されているカテゴリ:")
            for cat in categories:
                types_count = len(cat.garbage_types)
                print(f"  - {cat.category} ({cat.date}) - {types_count}種類")

def add_category(name, day, method, notion=""):
    """新しいカテゴリを追加"""
    app = createApp()
    with app.app_context():
        category = GarbageCategory(
            category=name,
            date=day,
            method=method,
            notion=notion,
            special_days=json.dumps([])
        )
        
        try:
            db.session.add(category)
            db.session.commit()
            print(f"✅ カテゴリ '{name}' を追加しました")
        except Exception as e:
            db.session.rollback()
            print(f"❌ エラー: {str(e)}")

def main():
    parser = argparse.ArgumentParser(description='データベース管理スクリプト')
    parser.add_argument('command', choices=['init', 'seed', 'reset', 'status', 'add-category', 'import-json'], 
                       help='実行するコマンド')
    
    # add-category用のオプション
    parser.add_argument('--name', help='カテゴリ名')
    parser.add_argument('--day', help='回収曜日')
    parser.add_argument('--method', help='回収方法')
    parser.add_argument('--notion', default='', help='注意事項')
    
    # import-json用のオプション
    parser.add_argument('--file', help='インポートするJSONファイルのパス')
    
    args = parser.parse_args()
    
    print("=== Home Garbage Assistance - Database Manager ===")
    print()
    
    try:
        if args.command == 'init':
            init_database()
            
        elif args.command == 'seed':
            seed_database()
            
        elif args.command == 'reset':
            reset_database()
            
        elif args.command == 'status':
            show_status()
            
        elif args.command == 'add-category':
            if not all([args.name, args.day, args.method]):
                print("❌ --name, --day, --method は必須です")
                return
            add_category(args.name, args.day, args.method, args.notion)
            
        elif args.command == 'import-json':
            if not args.file:
                print("❌ --file オプションでJSONファイルを指定してください")
                return
            import_json_file(args.file)
            
        elif args.command == 'seed':
            init_database()  # テーブルが存在しない場合に作成
            seed_database()
            
        elif args.command == 'reset':
            reset_database()
            
        elif args.command == 'status':
            show_status()
            
        elif args.command == 'add-category':
            if not all([args.name, args.day, args.method]):
                print("❌ --name, --day, --method は必須です")
                return
            add_category(args.name, args.day, args.method, args.notion)
            
        print("\n🎉 操作が完了しました！")
        
    except Exception as e:
        print(f"❌ エラーが発生しました: {str(e)}")
        sys.exit(1)

if __name__ == '__main__':
    main()
