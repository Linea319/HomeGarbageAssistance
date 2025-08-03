<!-- データ管理メイン画面 -->
<template>
  <div class="admin-container">
    <header class="admin-header">
      <div class="header-content">
        <button @click="$emit('close')" class="back-button">
          ← 戻る
        </button>
        <h1>データ管理</h1>
      </div>
    </header>

    <div class="admin-content">
      <!-- 操作ボタン群 -->
      <div class="action-buttons">
        <button @click="showCreateModal = true" class="btn-primary">
          ➕ 新規追加
        </button>
        <button @click="exportData" class="btn-secondary">
          📤 エクスポート
        </button>
        <button @click="showImportModal = true" class="btn-secondary">
          📥 インポート
        </button>
        <button @click="resetData" class="btn-danger" :disabled="isLoading">
          🔄 リセット
        </button>
      </div>

      <!-- 統計情報 -->
      <div class="stats-container">
        <div class="stat-card">
          <h3>{{ categories.length }}</h3>
          <p>カテゴリ数</p>
        </div>
        <div class="stat-card">
          <h3>{{ totalGarbageTypes }}</h3>
          <p>ゴミ種類数</p>
        </div>
      </div>

      <!-- カテゴリ一覧 -->
      <div class="categories-list">
        <div v-if="isLoading" class="loading">
          データを読み込み中...
        </div>
        
        <div v-else-if="categories.length === 0" class="empty-state">
          <p>📝 カテゴリが登録されていません</p>
          <button @click="showCreateModal = true" class="btn-primary">
            最初のカテゴリを追加
          </button>
        </div>

        <div v-else class="category-grid">
          <div
            v-for="category in categories"
            :key="category.id"
            class="category-card"
          >
            <div class="card-header">
              <h3>{{ category.category }}</h3>
              <div class="card-actions">
                <button @click="editCategory(category)" class="btn-edit">
                  ✏️
                </button>
                <button @click="deleteCategory(category)" class="btn-delete">
                  🗑️
                </button>
              </div>
            </div>
            
            <div class="card-body">
              <p v-for="date in category.date" :key="date"><strong>回収日:</strong> {{ formatDay(date) }}</p>
              <p><strong>方法:</strong> {{ category.method }}</p>
              <p><strong>ゴミ種類:</strong> {{ category.garbage_types_count }}件</p>
              
              <div class="garbage-types">
                <span
                  v-for="type in category.garbage_types"
                  :key="type.id"
                  class="type-tag"
                >
                  {{ type.name }}
                </span>
              </div>
              
              <div v-if="category.notion" class="notion">
                <small>{{ category.notion }}</small>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>

    <!-- 作成・編集モーダル -->
    <CategoryFormModal
      v-if="showCreateModal || showEditModal"
      :category="editingCategory"
      @save="saveCategory"
      @cancel="cancelEdit"
    />

    <!-- インポートモーダル -->
    <ImportModal
      v-if="showImportModal"
      @import="importData"
      @cancel="showImportModal = false"
    />

    <!-- 通知メッセージ -->
    <div v-if="notification" :class="['notification', notification.type]">
      {{ notification.message }}
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted, computed } from 'vue';
import { AdminApiClient, type CategoryData, type CategoryFormData } from '../composables/useAdminApi';
import CategoryFormModal from './CategoryFormModal.vue';
import ImportModal from './ImportModal.vue';

defineEmits<{
  close: [];
}>();

const adminApi = new AdminApiClient();
const categories = ref<CategoryData[]>([]);
const isLoading = ref(false);
const showCreateModal = ref(false);
const showEditModal = ref(false);
const showImportModal = ref(false);
const editingCategory = ref<CategoryData | null>(null);
const notification = ref<{ message: string; type: 'success' | 'error' } | null>(null);

const totalGarbageTypes = computed(() => {
  return categories.value.reduce((sum, cat) => sum + cat.garbage_types_count, 0);
});

const dayNames: Record<string, string> = {
  'Monday': '月曜日',
  'Tuesday': '火曜日', 
  'Wednesday': '水曜日',
  'Thursday': '木曜日',
  'Friday': '金曜日',
  'Saturday': '土曜日',
  'Sunday': '日曜日'
};

const formatDay = (day: string): string => {
  return dayNames[day] || day;
};

const showNotification = (message: string, type: 'success' | 'error' = 'success') => {
  notification.value = { message, type };
  setTimeout(() => {
    notification.value = null;
  }, 3000);
};

const loadCategories = async () => {
  isLoading.value = true;
  try {
    const response = await adminApi.getCategories();
    if (response.success && response.data) {
      categories.value = response.data;
    } else {
      showNotification(response.error || 'データの読み込みに失敗しました', 'error');
    }
  } catch (error) {
    showNotification('データの読み込み中にエラーが発生しました', 'error');
  } finally {
    isLoading.value = false;
  }
};

const editCategory = (category: CategoryData) => {
  editingCategory.value = category;
  showEditModal.value = true;
};

const deleteCategory = async (category: CategoryData) => {
  if (!confirm(`「${category.category}」を削除しますか？\nこの操作は取り消せません。`)) {
    return;
  }

  try {
    const response = await adminApi.deleteCategory(category.id);
    if (response.success) {
      showNotification(response.message || 'カテゴリを削除しました');
      await loadCategories();
    } else {
      showNotification(response.error || '削除に失敗しました', 'error');
    }
  } catch (error) {
    showNotification('削除中にエラーが発生しました', 'error');
  }
};

const saveCategory = async (data: CategoryFormData) => {
  try {
    let response;
    if (editingCategory.value) {
      // 更新
      response = await adminApi.updateCategory(editingCategory.value.id, data);
    } else {
      // 新規作成
      response = await adminApi.createCategory(data);
    }

    if (response.success) {
      showNotification(response.message || 'カテゴリを保存しました');
      await loadCategories();
      cancelEdit();
    } else {
      showNotification(response.error || '保存に失敗しました', 'error');
    }
  } catch (error) {
    showNotification('保存中にエラーが発生しました', 'error');
  }
};

const cancelEdit = () => {
  showCreateModal.value = false;
  showEditModal.value = false;
  editingCategory.value = null;
};

const exportData = async () => {
  try {
    const response = await adminApi.exportData();
    if (response.success && response.data) {
      // JSONファイルとしてダウンロード
      const blob = new Blob([JSON.stringify(response.data, null, 2)], {
        type: 'application/json'
      });
      const url = URL.createObjectURL(blob);
      const a = document.createElement('a');
      a.href = url;
      a.download = `garbage_data_${new Date().toISOString().slice(0, 10)}.json`;
      document.body.appendChild(a);
      a.click();
      document.body.removeChild(a);
      URL.revokeObjectURL(url);
      
      showNotification('データをエクスポートしました');
    } else {
      showNotification(response.error || 'エクスポートに失敗しました', 'error');
    }
  } catch (error) {
    showNotification('エクスポート中にエラーが発生しました', 'error');
  }
};

const importData = async (data: any, clearExisting: boolean) => {
  try {
    const response = await adminApi.importData(data, clearExisting);
    if (response.success) {
      showNotification(response.message || 'データをインポートしました');
      await loadCategories();
      showImportModal.value = false;
    } else {
      showNotification(response.error || 'インポートに失敗しました', 'error');
    }
  } catch (error) {
    showNotification('インポート中にエラーが発生しました', 'error');
  }
};

const resetData = async () => {
  if (!confirm('データベースをデフォルト状態にリセットしますか？\n現在のデータは全て削除されます。')) {
    return;
  }

  try {
    const response = await adminApi.resetDatabase();
    if (response.success) {
      showNotification(response.message || 'データベースをリセットしました');
      await loadCategories();
    } else {
      showNotification(response.error || 'リセットに失敗しました', 'error');
    }
  } catch (error) {
    showNotification('リセット中にエラーが発生しました', 'error');
  }
};

onMounted(() => {
  loadCategories();
});
</script>

<style scoped>
.admin-container {
  min-height: 100vh;
  background: #f5f7fa;
}

.admin-header {
  background: white;
  border-bottom: 1px solid #e1e5e9;
  padding: 1rem 0;
}

.header-content {
  max-width: 1200px;
  margin: 0 auto;
  padding: 0 1rem;
  display: flex;
  align-items: center;
  gap: 1rem;
}

.back-button {
  background: none;
  border: none;
  font-size: 1rem;
  color: #666;
  cursor: pointer;
  padding: 0.5rem;
  border-radius: 4px;
  transition: background-color 0.2s;
}

.back-button:hover {
  background: #f0f0f0;
}

.admin-content {
  max-width: 1200px;
  margin: 0 auto;
  padding: 2rem 1rem;
}

.action-buttons {
  display: flex;
  gap: 1rem;
  margin-bottom: 2rem;
  flex-wrap: wrap;
}

.btn-primary, .btn-secondary, .btn-danger {
  padding: 0.75rem 1.5rem;
  border: none;
  border-radius: 6px;
  font-weight: 500;
  cursor: pointer;
  transition: all 0.2s;
}

.btn-primary {
  background: #007bff;
  color: white;
}

.btn-primary:hover {
  background: #0056b3;
}

.btn-secondary {
  background: #6c757d;
  color: white;
}

.btn-secondary:hover {
  background: #545b62;
}

.btn-danger {
  background: #dc3545;
  color: white;
}

.btn-danger:hover {
  background: #c82333;
}

.btn-danger:disabled {
  background: #ccc;
  cursor: not-allowed;
}

.stats-container {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
  gap: 1rem;
  margin-bottom: 2rem;
}

.stat-card {
  background: white;
  padding: 1.5rem;
  border-radius: 8px;
  box-shadow: 0 2px 4px rgba(0,0,0,0.1);
  text-align: center;
}

.stat-card h3 {
  font-size: 2rem;
  color: #007bff;
  margin: 0 0 0.5rem 0;
}

.stat-card p {
  margin: 0;
  color: #666;
}

.loading {
  text-align: center;
  padding: 3rem;
  color: #666;
}

.empty-state {
  text-align: center;
  padding: 3rem;
  background: white;
  border-radius: 8px;
  box-shadow: 0 2px 4px rgba(0,0,0,0.1);
}

.category-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(350px, 1fr));
  gap: 1.5rem;
}

.category-card {
  background: white;
  border-radius: 8px;
  box-shadow: 0 2px 4px rgba(0,0,0,0.1);
  overflow: hidden;
  transition: transform 0.2s, box-shadow 0.2s;
}

.category-card:hover {
  transform: translateY(-2px);
  box-shadow: 0 4px 8px rgba(0,0,0,0.15);
}

.card-header {
  background: #f8f9fa;
  padding: 1rem;
  display: flex;
  justify-content: space-between;
  align-items: center;
  border-bottom: 1px solid #e1e5e9;
}

.card-header h3 {
  margin: 0;
  color: #333;
}

.card-actions {
  display: flex;
  gap: 0.5rem;
}

.btn-edit, .btn-delete {
  background: none;
  border: none;
  padding: 0.5rem;
  border-radius: 4px;
  cursor: pointer;
  transition: background-color 0.2s;
}

.btn-edit:hover {
  background: #e3f2fd;
}

.btn-delete:hover {
  background: #ffebee;
}

.card-body {
  padding: 1rem;
}

.card-body p {
  margin: 0 0 0.5rem 0;
  color: #666;
}

.garbage-types {
  margin: 1rem 0;
  display: flex;
  flex-wrap: wrap;
  gap: 0.5rem;
}

.type-tag {
  background: #e3f2fd;
  color: #1976d2;
  padding: 0.25rem 0.5rem;
  border-radius: 12px;
  font-size: 0.875rem;
}

.notion {
  margin-top: 1rem;
  padding-top: 1rem;
  border-top: 1px solid #e1e5e9;
}

.notion small {
  color: #888;
  font-style: italic;
}

.notification {
  position: fixed;
  top: 20px;
  right: 20px;
  padding: 1rem 1.5rem;
  border-radius: 6px;
  color: white;
  font-weight: 500;
  z-index: 1000;
  animation: slideIn 0.3s ease;
}

.notification.success {
  background: #28a745;
}

.notification.error {
  background: #dc3545;
}

@keyframes slideIn {
  from {
    transform: translateX(100%);
    opacity: 0;
  }
  to {
    transform: translateX(0);
    opacity: 1;
  }
}

@media (max-width: 768px) {
  .admin-content {
    padding: 1rem;
  }
  
  .action-buttons {
    flex-direction: column;
  }
  
  .category-grid {
    grid-template-columns: 1fr;
  }
}
</style>
