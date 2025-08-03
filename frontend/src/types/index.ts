/**
 * アプリケーション全体で使用する型定義
 * ゴミカテゴリとゴミ種類のデータ構造を定義する
 */

export interface GarbageCategory {
  id: number;
  category: string;
  date: string;
  method: string;
  special_days: string[];
  notion: string;
  garbage_types: GarbageType[];
}

export interface GarbageType {
  id: number;
  name: string;
  category_id: number;
  category?: string;
}

export interface SearchResult {
  garbage_type: GarbageType;
  category: GarbageCategory;
}

export interface ApiResponse<T> {
  success: boolean;
  data?: T;
  error?: string;
  message?: string;
  found?: boolean;
  query?: string;
  today?: string;
}

export type DayOfWeek = 'Monday' | 'Tuesday' | 'Wednesday' | 'Thursday' | 'Friday' | 'Saturday' | 'Sunday';

export const DAYS_JP: Record<DayOfWeek, string> = {
  'Monday': '月曜日',
  'Tuesday': '火曜日',
  'Wednesday': '水曜日',
  'Thursday': '木曜日',
  'Friday': '金曜日',
  'Saturday': '土曜日',
  'Sunday': '日曜日'
};
