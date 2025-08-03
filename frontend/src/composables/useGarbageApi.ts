/**
 * API通信を管理するComposable
 * バックエンドとの通信処理を一元管理する
 */

/// <reference types="vite/client" />

import { ref, type Ref } from 'vue';
import type { GarbageCategory, SearchResult, ApiResponse, DayOfWeek } from '@/types';

const API_BASE_URL = import.meta.env.VITE_API_URL|| 'http://localhost:5000/api';

export function useGarbageApi() {
  const loading: Ref<boolean> = ref(false);
  const error: Ref<string | null> = ref(null);

  /**
   * APIリクエストを実行する共通関数
   * エラーハンドリングとローディング状態を管理する
   */
  async function apiRequest<T>(endpoint: string): Promise<T | null> {
    loading.value = true;
    error.value = null;
    
    try {
      const response = await fetch(`${API_BASE_URL}${endpoint}`);
      const data: ApiResponse<T> = await response.json();
      
      if (!data.success) {
        throw new Error(data.error || 'API request failed');
      }
      
      return data.data || null;
    } catch (err) {
      error.value = err instanceof Error ? err.message : 'Unknown error occurred';
      return null;
    } finally {
      loading.value = false;
    }
  }

  /**
   * 全てのゴミカテゴリを取得する
   */
  async function getAllCategories(): Promise<GarbageCategory[]> {
    const data = await apiRequest<GarbageCategory[]>('/categories');
    return data || [];
  }

  /**
   * 指定された曜日のゴミカテゴリを取得する
   */
  async function getCategoriesByDay(day: DayOfWeek): Promise<GarbageCategory[]> {
    const data = await apiRequest<GarbageCategory[]>(`/categories?day=${day}`);
    return data || [];
  }

  /**
   * 今日のゴミカテゴリを取得する
   */
  async function getTodayCategories(): Promise<{ today: string; data: GarbageCategory[] }> {
    loading.value = true;
    error.value = null;
    
    try {
      const response = await fetch(`${API_BASE_URL}/categories/today`);
      const result: ApiResponse<GarbageCategory[]> & { today?: string } = await response.json();
      
      if (!result.success) {
        throw new Error(result.error || 'API request failed');
      }
      
      return {
        today: result.today || '',
        data: result.data || []
      };
    } catch (err) {
      error.value = err instanceof Error ? err.message : 'Unknown error occurred';
      return { today: '', data: [] };
    } finally {
      loading.value = false;
    }
  }

  /**
   * ゴミの種類で逆検索を実行する
   */
  async function searchGarbageType(query: string): Promise<SearchResult[]> {
    if (!query.trim()) return [];
    
    loading.value = true;
    error.value = null;
    
    try {
      const response = await fetch(`${API_BASE_URL}/search?q=${encodeURIComponent(query)}`);
      const result: ApiResponse<SearchResult[]> & { found?: boolean } = await response.json();
      
      if (!result.success) {
        throw new Error(result.error || 'Search failed');
      }
      
      if (!result.found) {
        return [];
      }
      
      return result.data || [];
    } catch (err) {
      error.value = err instanceof Error ? err.message : 'Unknown error occurred';
      return [];
    } finally {
      loading.value = false;
    }
  }

  /**
   * 指定されたIDのカテゴリ詳細を取得する
   */
  async function getCategoryById(id: number): Promise<GarbageCategory | null> {
    const data = await apiRequest<GarbageCategory>(`/categories/${id}`);
    return data;
  }

  /**
   * アプリケーションのヘルスチェックを実行する
   */
  async function healthCheck(): Promise<boolean> {
    try {
      const response = await fetch(`${API_BASE_URL}/health`);
      const data = await response.json();
      return data.status === 'healthy';
    } catch {
      return false;
    }
  }

  return {
    loading,
    error,
    getAllCategories,
    getCategoriesByDay,
    getTodayCategories,
    searchGarbageType,
    getCategoryById,
    healthCheck
  };
}
