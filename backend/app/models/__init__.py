"""
データベースモデルを定義するファイル
ゴミカテゴリとゴミ種類のデータモデルを管理する
"""

from flask_sqlalchemy import SQLAlchemy
from datetime import datetime
from typing import List, Optional

db = SQLAlchemy()


class GarbageCategory(db.Model):
    """
    ゴミのカテゴリデータを管理するクラス
    カテゴリごとの回収日、回収方法、特別日などの情報を保持する
    """
    __tablename__ = 'garbage_categories'
    
    id = db.Column(db.Integer, primary_key=True)
    category = db.Column(db.String(100), nullable=False, unique=True)
    date = db.Column(db.String(20), nullable=False)  # Monday, Tuesday, etc.
    method = db.Column(db.String(200), nullable=False)
    special_days = db.Column(db.Text)  # JSON string for special collection days
    notion = db.Column(db.Text)  # Additional notes
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    updated_at = db.Column(db.DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    
    # Relationship with GarbageType
    garbage_types = db.relationship('GarbageType', backref='category_ref', lazy=True)
    
    def to_dict(self) -> dict:
        """
        オブジェクトを辞書形式に変換する
        Returns:
            dict: カテゴリ情報の辞書
        """
        import json
        special_days_list = []
        if self.special_days:
            try:
                special_days_list = json.loads(self.special_days)
            except json.JSONDecodeError:
                special_days_list = []
                
        return {
            'id': self.id,
            'category': self.category,
            'date': self.date,
            'method': self.method,
            'special_days': special_days_list,
            'notion': self.notion,
            'garbage_types': [gt.to_dict() for gt in self.garbage_types]
        }


class GarbageType(db.Model):
    """
    ゴミの種類データを管理するクラス
    個別のゴミの種類とカテゴリの関連を管理する
    """
    __tablename__ = 'garbage_types'
    
    id = db.Column(db.Integer, primary_key=True)
    name = db.Column(db.String(100), nullable=False)
    category_id = db.Column(db.Integer, db.ForeignKey('garbage_categories.id'), nullable=False)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    updated_at = db.Column(db.DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    
    def to_dict(self) -> dict:
        """
        オブジェクトを辞書形式に変換する
        Returns:
            dict: ゴミ種類情報の辞書
        """
        return {
            'id': self.id,
            'name': self.name,
            'category_id': self.category_id,
            'category': self.category_ref.category if self.category_ref else None
        }
