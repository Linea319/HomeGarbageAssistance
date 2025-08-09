/**
 * データ管理画面用のAPIクライアント
 * 管理用APIエンドポイントとの通信を管理
 */

interface CategoryFormData {
  category: string;
  date: string[] | string; // 複数曜日対応
  method: string;
  special_days: string[];
  notion: string;
  garbage_types: string[];
}

interface CategoryData {
  id: number;
  category: string;
  date: string[] | string; // 複数曜日対応
  method: string;
  special_days: string[];
  notion: string;
  garbage_types_count: number;
  created_at: string;
  updated_at: string;
  garbage_types: Array<{
    id: number;
    name: string;
    category_id: number;
  }>;
}

interface ApiResponse<T> {
  success: boolean;
  data?: T;
  error?: string;
  message?: string;
  total?: number;
}

export class AdminApiClient {
  private baseUrl: string;

  constructor() {
    this.baseUrl = import.meta.env.VITE_API_URL || 'http://localhost:5100';
  }

  private async request<T>(
    endpoint: string,
    options: RequestInit = {}
  ): Promise<ApiResponse<T>> {
    try {
      const response = await fetch(`${this.baseUrl}/admin${endpoint}`, {
        headers: {
          'Content-Type': 'application/json',
          ...options.headers,
        },
        ...options,
      });

      const data = await response.json();
      
      if (!response.ok) {
        throw new Error(data.error || `HTTP ${response.status}`);
      }

      return data;
    } catch (error) {
      console.error('API request failed:', error);
      return {
        success: false,
        error: error instanceof Error ? error.message : 'Unknown error'
      };
    }
  }

  // カテゴリ一覧取得
  async getCategories(): Promise<ApiResponse<CategoryData[]>> {
    return this.request<CategoryData[]>('/categories');
  }

  // カテゴリ作成
  async createCategory(data: CategoryFormData): Promise<ApiResponse<CategoryData>> {
    return this.request<CategoryData>('/categories', {
      method: 'POST',
      body: JSON.stringify(data),
    });
  }

  // カテゴリ更新
  async updateCategory(id: number, data: Partial<CategoryFormData>): Promise<ApiResponse<CategoryData>> {
    return this.request<CategoryData>(`/categories/${id}`, {
      method: 'PUT',
      body: JSON.stringify(data),
    });
  }

  // カテゴリ削除
  async deleteCategory(id: number): Promise<ApiResponse<void>> {
    return this.request<void>(`/categories/${id}`, {
      method: 'DELETE',
    });
  }

  // データエクスポート
  async exportData(): Promise<ApiResponse<any>> {
    return this.request<any>('/export');
  }

  // データインポート
  async importData(data: any, clearExisting = false): Promise<ApiResponse<any>> {
    return this.request<any>('/import', {
      method: 'POST',
      body: JSON.stringify({
        data,
        clear_existing: clearExisting
      }),
    });
  }

  // データベースリセット
  async resetDatabase(): Promise<ApiResponse<any>> {
    return this.request<any>('/reset', {
      method: 'POST',
    });
  }
}

export type { CategoryFormData, CategoryData, ApiResponse };
