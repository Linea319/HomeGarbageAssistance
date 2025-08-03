/**
 * アプリケーション全体で使用する型定義
 * ゴミカテゴリとゴミ種類のデータ構造を定義する
 */

export interface GarbageCategory {
  id: number;
  category: string;
  date: string[] | string; // 複数曜日対応：配列または文字列
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

/**
 * 日付フィールドを配列として取得する（後方互換性対応）
 */
export function getDaysAsArray(date: string[] | string): string[] {
  return Array.isArray(date) ? date : [date];
}

/**
 * 複数曜日を日本語で表示する
 */
export function formatDaysJapanese(date: string[] | string): string {
  const days = getDaysAsArray(date);
  return days.map(day => DAYS_JP[day as DayOfWeek] || day).join('・');
}
