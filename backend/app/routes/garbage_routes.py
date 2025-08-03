"""
ゴミ情報に関するAPIルートを定義するファイル
曜日別のゴミ情報取得と逆検索機能を提供する
"""

from flask import Blueprint, jsonify, request
from app.models import db, GarbageCategory, GarbageType
from datetime import datetime
from typing import List, Dict, Any
import json

garbage_bp = Blueprint('garbage', __name__)


@garbage_bp.route('/api/categories', methods=['GET'])
def getCategoriesByDay():
    """
    指定された曜日のゴミカテゴリ情報を取得する
    クエリパラメータで曜日を指定しない場合は全曜日の情報を返す
    Returns:
        JSON: カテゴリ情報のリスト
    """
    day = request.args.get('day')
    
    try:
        if day:
            # 複数曜日対応：指定された曜日が含まれるカテゴリを抽出
            all_categories = GarbageCategory.query.all()
            filtered_categories = []
            
            for category in all_categories:
                try:
                    date_list = json.loads(category.date)
                    # 後方互換性のため、文字列の場合も対応
                    if isinstance(date_list, str):
                        date_list = [date_list]
                    
                    if day in date_list:
                        filtered_categories.append(category)
                        
                except json.JSONDecodeError:
                    # JSONでない場合は単一の文字列として比較
                    if category.date == day:
                        filtered_categories.append(category)
            
            categories = filtered_categories
        else:
            categories = GarbageCategory.query.all()
            
        return jsonify({
            'success': True,
            'data': [category.to_dict() for category in categories]
        })
    except Exception as e:
        return jsonify({
            'success': False,
            'error': str(e)
        }), 500


@garbage_bp.route('/api/categories/today', methods=['GET'])
def getTodayCategories():
    """
    今日の曜日に対応するゴミカテゴリ情報を取得する
    Returns:
        JSON: 今日のカテゴリ情報のリスト
    """
    try:
        # 現在の曜日を取得
        today = datetime.now().strftime('%A')  # Monday, Tuesday, etc.
        
        # 複数曜日対応：dateフィールドがJSONで格納されているため
        # すべてのカテゴリを取得して、今日の曜日が含まれているものを抽出
        all_categories = GarbageCategory.query.all()
        today_categories = []
        
        for category in all_categories:
            try:
                date_list = json.loads(category.date)
                # 後方互換性のため、文字列の場合も対応
                if isinstance(date_list, str):
                    date_list = [date_list]
                
                if today in date_list:
                    today_categories.append(category)
                    
            except json.JSONDecodeError:
                # JSONでない場合は単一の文字列として比較
                if category.date == today:
                    today_categories.append(category)
        
        return jsonify({
            'success': True,
            'today': today,
            'data': [category.to_dict() for category in today_categories]
        })
    except Exception as e:
        return jsonify({
            'success': False,
            'error': str(e)
        }), 500


@garbage_bp.route('/api/search', methods=['GET'])
def searchGarbageType():
    """
    ゴミの種類名で逆検索を行う
    Args:
        q (str): 検索するゴミの種類名
    Returns:
        JSON: 検索結果とカテゴリ情報
    """
    query = request.args.get('q', '').strip()
    
    if not query:
        return jsonify({
            'success': False,
            'error': 'Search query is required'
        }), 400
    
    try:
        # ゴミの種類名で部分一致検索
        garbage_types = GarbageType.query.filter(
            GarbageType.name.contains(query)
        ).all()
        
        if not garbage_types:
            return jsonify({
                'success': True,
                'found': False,
                'message': f'「{query}」に関するゴミ情報が見つかりませんでした'
            })
        
        # 見つかったゴミ種類とそのカテゴリ情報を返す
        results = []
        for garbage_type in garbage_types:
            results.append({
                'garbage_type': garbage_type.to_dict(),
                'category': garbage_type.category_ref.to_dict() if garbage_type.category_ref else None
            })
        
        return jsonify({
            'success': True,
            'found': True,
            'query': query,
            'data': results
        })
    except Exception as e:
        return jsonify({
            'success': False,
            'error': str(e)
        }), 500


@garbage_bp.route('/api/categories/<int:categoryId>', methods=['GET'])
def getCategoryById(categoryId: int):
    """
    指定されたIDのカテゴリ情報を取得する
    Args:
        categoryId (int): カテゴリID
    Returns:
        JSON: カテゴリ情報
    """
    try:
        category = GarbageCategory.query.get_or_404(categoryId)
        
        return jsonify({
            'success': True,
            'data': category.to_dict()
        })
    except Exception as e:
        return jsonify({
            'success': False,
            'error': str(e)
        }), 500
