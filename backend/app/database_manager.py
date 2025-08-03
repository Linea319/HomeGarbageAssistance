"""
データベースとJSONファイル間の変換機能を提供するモジュール
データのエクスポート・インポート機能を管理
"""

import json
import os
from datetime import datetime
from app.models import db, GarbageCategory, GarbageType
from flask import current_app

class DatabaseManager:
    """データベース管理クラス"""
    
    @staticmethod
    def export_to_json(filepath: str = None) -> dict:
        """
        データベースの内容をJSONファイルにエクスポート
        Args:
            filepath (str): 出力先ファイルパス（省略時は data/backup.json）
        Returns:
            dict: エクスポートされたデータ
        """
        if filepath is None:
            os.makedirs('data', exist_ok=True)
            filepath = f'data/backup_{datetime.now().strftime("%Y%m%d_%H%M%S")}.json'
        
        # データベースからデータを取得
        categories = GarbageCategory.query.all()
        
        export_data = {
            'metadata': {
                'export_date': datetime.now().isoformat(),
                'version': '1.0',
                'total_categories': len(categories),
                'total_garbage_types': GarbageType.query.count()
            },
            'categories': []
        }
        
        for category in categories:
            # dateフィールドの処理（複数曜日対応）
            date_list = []
            if category.date:
                try:
                    date_list = json.loads(category.date)
                    # 後方互換性のため、文字列の場合は配列に変換
                    if isinstance(date_list, str):
                        date_list = [date_list]
                except json.JSONDecodeError:
                    # JSONでない場合は単一の文字列として扱う
                    date_list = [category.date]
            
            category_data = {
                'category': category.category,
                'date': date_list,
                'method': category.method,
                'special_days': json.loads(category.special_days) if category.special_days else [],
                'notion': category.notion,
                'garbage_types': [gt.name for gt in category.garbage_types]
            }
            export_data['categories'].append(category_data)
        
        # ファイルに保存
        os.makedirs(os.path.dirname(filepath) if os.path.dirname(filepath) else '.', exist_ok=True)
        with open(filepath, 'w', encoding='utf-8') as f:
            json.dump(export_data, f, ensure_ascii=False, indent=2)
        
        return export_data
    
    @staticmethod
    def import_from_json(filepath: str, clear_existing: bool = False) -> dict:
        """
        JSONファイルからデータベースにインポート
        Args:
            filepath (str): インポート元ファイルパス
            clear_existing (bool): 既存データを削除するか
        Returns:
            dict: インポート結果の統計情報
        """
        if not os.path.exists(filepath):
            raise FileNotFoundError(f"ファイルが見つかりません: {filepath}")
        
        with open(filepath, 'r', encoding='utf-8') as f:
            import_data = json.load(f)
        
        if clear_existing:
            db.session.query(GarbageType).delete()
            db.session.query(GarbageCategory).delete()
            db.session.commit()
        
        imported_categories = 0
        imported_garbage_types = 0
        skipped_categories = 0
        
        for category_data in import_data.get('categories', []):
            # 既存カテゴリをチェック
            existing_category = GarbageCategory.query.filter_by(
                category=category_data['category']
            ).first()
            
            if existing_category and not clear_existing:
                skipped_categories += 1
                continue
            
            # カテゴリを作成
            # dateフィールドの処理（複数曜日対応）
            date_value = category_data['date']
            if isinstance(date_value, list):
                # 配列の場合はJSON文字列として保存
                date_json = json.dumps(date_value)
            else:
                # 文字列の場合は配列に変換してからJSON文字列として保存
                date_json = json.dumps([date_value])
            
            category = GarbageCategory(
                category=category_data['category'],
                date=date_json,
                method=category_data['method'],
                special_days=json.dumps(category_data.get('special_days', [])),
                notion=category_data.get('notion', '')
            )
            
            db.session.add(category)
            db.session.flush()  # IDを取得するため
            imported_categories += 1
            
            # ゴミ種類を追加
            for garbage_name in category_data.get('garbage_types', []):
                garbage_type = GarbageType(
                    name=garbage_name,
                    category_id=category.id
                )
                db.session.add(garbage_type)
                imported_garbage_types += 1
        
        db.session.commit()
        
        return {
            'imported_categories': imported_categories,
            'imported_garbage_types': imported_garbage_types,
            'skipped_categories': skipped_categories,
            'total_categories': GarbageCategory.query.count(),
            'total_garbage_types': GarbageType.query.count()
        }
    
    @staticmethod
    def get_default_data() -> dict:
        """
        デフォルトのサンプルデータを取得
        Returns:
            dict: デフォルトデータ
        """
        return {
            'metadata': {
                'export_date': datetime.now().isoformat(),
                'version': '1.0',
                'description': 'デフォルトサンプルデータ'
            },
            'categories': [
                {
                    'category': '可燃ゴミ',
                    'date': 'Monday',
                    'method': '専用ゴミ袋に入れて出してください',
                    'special_days': ['2024-04-11', '2024-04-25'],
                    'notion': '生ごみは水気をよく切ってから出してください',
                    'garbage_types': ['生ごみ', '紙くず', '木くず']
                },
                {
                    'category': '不燃ゴミ',
                    'date': 'Wednesday',
                    'method': '透明または半透明の袋に入れて出してください',
                    'special_days': [],
                    'notion': '金属類は分別してください',
                    'garbage_types': ['金属類', 'ガラス', '陶器']
                },
                {
                    'category': 'プラスチック',
                    'date': 'Friday',
                    'method': 'プラマークの付いた容器のみ',
                    'special_days': [],
                    'notion': '汚れを落としてから出してください',
                    'garbage_types': ['プラスチック容器']
                },
                {
                    'category': '資源ゴミ',
                    'date': 'Saturday',
                    'method': '種類別に分けて出してください',
                    'special_days': [],
                    'notion': 'ペットボトル、缶、ビンを分別',
                    'garbage_types': ['ペットボトル', '空き缶', 'ビン']
                }
            ]
        }
