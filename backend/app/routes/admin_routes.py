"""
データベース管理用のAPIルート
CRUD操作とデータのインポート・エクスポート機能を提供
"""

from flask import Blueprint, request, jsonify
from app.models import db, GarbageCategory, GarbageType
from app.database_manager import DatabaseManager
import json
import os

admin_bp = Blueprint('admin', __name__, url_prefix='/api/admin')

@admin_bp.route('/categories', methods=['GET'])
def get_all_categories_admin():
    """
    管理画面用: 全カテゴリを詳細情報付きで取得
    Returns:
        JSON: カテゴリ一覧（管理用詳細情報含む）
    """
    try:
        categories = GarbageCategory.query.all()
        result = []
        
        for category in categories:
            category_data = category.to_dict()
            category_data['garbage_types_count'] = len(category.garbage_types)
            result.append(category_data)
        
        return jsonify({
            'success': True,
            'data': result,
            'total': len(result)
        })
    except Exception as e:
        return jsonify({
            'success': False,
            'error': str(e)
        }), 500

@admin_bp.route('/categories', methods=['POST'])
def create_category():
    """
    新しいカテゴリを作成
    Request Body:
        {
            "category": "カテゴリ名",
            "date": "回収曜日",
            "method": "回収方法",
            "special_days": ["特別回収日"],
            "notion": "注意事項",
            "garbage_types": ["ゴミ種類1", "ゴミ種類2"]
        }
    Returns:
        JSON: 作成されたカテゴリ情報
    """
    try:
        data = request.get_json()
        
        # 必須フィールドのチェック
        required_fields = ['category', 'date', 'method']
        for field in required_fields:
            if field not in data or not data[field]:
                return jsonify({
                    'success': False,
                    'error': f'必須フィールドが不足しています: {field}'
                }), 400
        
        # 既存カテゴリの重複チェック
        existing = GarbageCategory.query.filter_by(category=data['category']).first()
        if existing:
            return jsonify({
                'success': False,
                'error': 'このカテゴリは既に存在します'
            }), 409
        
        # カテゴリを作成
        # dateフィールドの処理（複数曜日対応）
        date_value = data['date']
        if isinstance(date_value, list):
            # 配列の場合はJSON文字列として保存
            date_json = json.dumps(date_value)
        else:
            # 文字列の場合は配列に変換してからJSON文字列として保存
            date_json = json.dumps([date_value])
        
        category = GarbageCategory(
            category=data['category'],
            date=date_json,
            method=data['method'],
            special_days=json.dumps(data.get('special_days', [])),
            notion=data.get('notion', '')
        )
        
        db.session.add(category)
        db.session.flush()  # IDを取得するため
        
        # ゴミ種類を追加
        for garbage_name in data.get('garbage_types', []):
            if garbage_name.strip():  # 空文字列を除外
                garbage_type = GarbageType(
                    name=garbage_name.strip(),
                    category_id=category.id
                )
                db.session.add(garbage_type)
        
        db.session.commit()
        
        return jsonify({
            'success': True,
            'data': category.to_dict(),
            'message': 'カテゴリが正常に作成されました'
        }), 201
        
    except Exception as e:
        db.session.rollback()
        return jsonify({
            'success': False,
            'error': str(e)
        }), 500

@admin_bp.route('/categories/<int:category_id>', methods=['PUT'])
def update_category(category_id):
    """
    カテゴリを更新
    Args:
        category_id (int): カテゴリID
    Returns:
        JSON: 更新されたカテゴリ情報
    """
    try:
        category = GarbageCategory.query.get_or_404(category_id)
        data = request.get_json()
        
        # カテゴリ情報を更新
        if 'category' in data:
            # 他のカテゴリと重複しないかチェック
            existing = GarbageCategory.query.filter(
                GarbageCategory.category == data['category'],
                GarbageCategory.id != category_id
            ).first()
            if existing:
                return jsonify({
                    'success': False,
                    'error': 'このカテゴリ名は既に使用されています'
                }), 409
            category.category = data['category']
        
        if 'date' in data:
            # dateフィールドの処理（複数曜日対応）
            date_value = data['date']
            if isinstance(date_value, list):
                # 配列の場合はJSON文字列として保存
                category.date = json.dumps(date_value)
            else:
                # 文字列の場合は配列に変換してからJSON文字列として保存
                category.date = json.dumps([date_value])
        if 'method' in data:
            category.method = data['method']
        if 'special_days' in data:
            category.special_days = json.dumps(data['special_days'])
        if 'notion' in data:
            category.notion = data['notion']
        
        # ゴミ種類を更新
        if 'garbage_types' in data:
            # 既存のゴミ種類を削除
            GarbageType.query.filter_by(category_id=category_id).delete()
            
            # 新しいゴミ種類を追加
            for garbage_name in data['garbage_types']:
                if garbage_name.strip():
                    garbage_type = GarbageType(
                        name=garbage_name.strip(),
                        category_id=category_id
                    )
                    db.session.add(garbage_type)
        
        db.session.commit()
        
        return jsonify({
            'success': True,
            'data': category.to_dict(),
            'message': 'カテゴリが正常に更新されました'
        })
        
    except Exception as e:
        db.session.rollback()
        return jsonify({
            'success': False,
            'error': str(e)
        }), 500

@admin_bp.route('/categories/<int:category_id>', methods=['DELETE'])
def delete_category(category_id):
    """
    カテゴリを削除
    Args:
        category_id (int): カテゴリID
    Returns:
        JSON: 削除結果
    """
    try:
        category = GarbageCategory.query.get_or_404(category_id)
        category_name = category.category
        
        # 関連するゴミ種類も自動的に削除される（cascade設定による）
        db.session.delete(category)
        db.session.commit()
        
        return jsonify({
            'success': True,
            'message': f'カテゴリ「{category_name}」が正常に削除されました'
        })
        
    except Exception as e:
        db.session.rollback()
        return jsonify({
            'success': False,
            'error': str(e)
        }), 500

@admin_bp.route('/export', methods=['GET'])
def export_data():
    """
    データベースの内容をJSONとしてエクスポート
    Returns:
        JSON: エクスポートされたデータ
    """
    try:
        export_data = DatabaseManager.export_to_json()
        return jsonify({
            'success': True,
            'data': export_data,
            'message': 'データのエクスポートが完了しました'
        })
    except Exception as e:
        return jsonify({
            'success': False,
            'error': str(e)
        }), 500

@admin_bp.route('/import', methods=['POST'])
def import_data():
    """
    JSONデータをデータベースにインポート
    Request Body:
        {
            "data": {JSON形式のデータ},
            "clear_existing": true/false
        }
    Returns:
        JSON: インポート結果
    """
    try:
        request_data = request.get_json()
        
        if 'data' not in request_data:
            return jsonify({
                'success': False,
                'error': 'インポートするデータが指定されていません'
            }), 400
        
        clear_existing = request_data.get('clear_existing', False)
        import_data = request_data['data']
        
        # 一時ファイルに保存してインポート
        temp_file = 'temp_import.json'
        with open(temp_file, 'w', encoding='utf-8') as f:
            json.dump(import_data, f, ensure_ascii=False, indent=2)
        
        try:
            result = DatabaseManager.import_from_json(temp_file, clear_existing)
            return jsonify({
                'success': True,
                'data': result,
                'message': 'データのインポートが完了しました'
            })
        finally:
            # 一時ファイルを削除
            if os.path.exists(temp_file):
                os.remove(temp_file)
                
    except Exception as e:
        return jsonify({
            'success': False,
            'error': str(e)
        }), 500

@admin_bp.route('/reset', methods=['POST'])
def reset_database():
    """
    データベースをデフォルトデータでリセット
    Returns:
        JSON: リセット結果
    """
    try:
        # 既存データを削除
        db.session.query(GarbageType).delete()
        db.session.query(GarbageCategory).delete()
        db.session.commit()
        
        # デフォルトデータをインポート
        default_data = DatabaseManager.get_default_data()
        temp_file = 'temp_default.json'
        with open(temp_file, 'w', encoding='utf-8') as f:
            json.dump(default_data, f, ensure_ascii=False, indent=2)
        
        try:
            result = DatabaseManager.import_from_json(temp_file, clear_existing=False)
            return jsonify({
                'success': True,
                'data': result,
                'message': 'データベースがデフォルトデータでリセットされました'
            })
        finally:
            if os.path.exists(temp_file):
                os.remove(temp_file)
                
    except Exception as e:
        db.session.rollback()
        return jsonify({
            'success': False,
            'error': str(e)
        }), 500
