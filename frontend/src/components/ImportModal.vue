<!-- インポートモーダル -->
<template>
  <div class="modal-overlay" @click="emit('cancel')">
    <div class="modal-content" @click.stop>
      <div class="modal-header">
        <h2>データインポート</h2>
        <button @click="emit('cancel')" class="close-button">✕</button>
      </div>

      <div class="modal-body">
        <div class="import-options">
          <div class="option-group">
            <h3>インポート方法を選択</h3>
            <label class="radio-option">
              <input 
                type="radio" 
                v-model="importMethod" 
                value="file"
              />
              <span>JSONファイルをアップロード</span>
            </label>
            <label class="radio-option">
              <input 
                type="radio" 
                v-model="importMethod" 
                value="text"
              />
              <span>JSON文字列を入力</span>
            </label>
          </div>

          <!-- ファイルアップロード -->
          <div v-if="importMethod === 'file'" class="file-upload">
            <input
              ref="fileInput"
              type="file"
              accept=".json"
              @change="handleFileSelect"
              class="file-input"
            />
            <div class="file-drop-zone" @drop="handleFileDrop" @dragover.prevent>
              <div v-if="!selectedFile" class="drop-text">
                <p>📁 JSONファイルをドラッグ&ドロップ</p>
                <p>または</p>
                <button type="button" @click="fileInput?.click()" class="browse-button">
                  ファイルを選択
                </button>
              </div>
              <div v-else class="selected-file">
                <p>✅ {{ selectedFile.name }}</p>
                <button type="button" @click="clearFile" class="clear-button">
                  削除
                </button>
              </div>
            </div>
          </div>

          <!-- テキスト入力 -->
          <div v-if="importMethod === 'text'" class="text-input">
            <label for="jsonText">JSON文字列:</label>
            <textarea
              id="jsonText"
              v-model="jsonText"
              placeholder="JSONデータを貼り付けてください..."
              rows="10"
              class="json-textarea"
            ></textarea>
          </div>

          <!-- 設定オプション -->
          <div class="settings">
            <label class="checkbox-option">
              <input 
                type="checkbox" 
                v-model="clearExisting"
              />
              <span>既存データを削除してからインポート</span>
            </label>
            <p class="warning-text" v-if="clearExisting">
              ⚠️ 既存のデータは全て削除されます
            </p>
          </div>

          <!-- プレビュー -->
          <div v-if="previewData" class="preview">
            <h4>インポートプレビュー</h4>
            <div class="preview-stats">
              <span class="stat">📊 カテゴリ: {{ previewData.categories?.length || 0 }}件</span>
              <span class="stat">🗓️ 作成日: {{ formatDate(previewData.metadata?.export_date) }}</span>
            </div>
            <div class="preview-categories">
              <div 
                v-for="category in (previewData.categories || []).slice(0, 3)" 
                :key="category.category"
                class="preview-category"
              >
                <strong>{{ category.category }}</strong> ({{ category.date }})
                <small>{{ category.garbage_types?.length || 0 }}種類</small>
              </div>
              <div v-if="(previewData.categories || []).length > 3" class="more-categories">
                ...他 {{ (previewData.categories || []).length - 3 }}件
              </div>
            </div>
          </div>

          <!-- エラー表示 -->
          <div v-if="error" class="error-message">
            ❌ {{ error }}
          </div>
        </div>
      </div>

      <div class="modal-footer">
        <button type="button" @click="emit('cancel')" class="btn-secondary">
          キャンセル
        </button>
        <button 
          type="button" 
          @click="executeImport" 
          class="btn-primary" 
          :disabled="!canImport || isLoading"
        >
          {{ isLoading ? 'インポート中...' : 'インポート実行' }}
        </button>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, watch } from 'vue';

const emit = defineEmits<{
  import: [data: any, clearExisting: boolean];
  cancel: [];
}>();

const fileInput = ref<HTMLInputElement>();
const importMethod = ref<'file' | 'text'>('file');
const selectedFile = ref<File | null>(null);
const jsonText = ref('');
const clearExisting = ref(false);
const previewData = ref<any>(null);
const error = ref('');
const isLoading = ref(false);

const canImport = computed(() => {
  return previewData.value && !error.value;
});

const formatDate = (dateString: string | undefined): string => {
  if (!dateString) return '不明';
  try {
    return new Date(dateString).toLocaleString('ja-JP');
  } catch {
    return dateString;
  }
};

const handleFileSelect = (event: Event) => {
  const target = event.target as HTMLInputElement;
  if (target.files && target.files[0]) {
    selectedFile.value = target.files[0];
    readFile(target.files[0]);
  }
};

const handleFileDrop = (event: DragEvent) => {
  event.preventDefault();
  const files = event.dataTransfer?.files;
  if (files && files[0]) {
    selectedFile.value = files[0];
    readFile(files[0]);
  }
};

const readFile = (file: File) => {
  const reader = new FileReader();
  reader.onload = (e) => {
    const content = e.target?.result as string;
    jsonText.value = content;
    validateAndPreview(content);
  };
  reader.readAsText(file);
};

const clearFile = () => {
  selectedFile.value = null;
  jsonText.value = '';
  previewData.value = null;
  error.value = '';
};

const validateAndPreview = (jsonString: string) => {
  error.value = '';
  previewData.value = null;

  if (!jsonString.trim()) {
    return;
  }

  try {
    const data = JSON.parse(jsonString);
    
    // 基本的なバリデーション
    if (!data.categories || !Array.isArray(data.categories)) {
      error.value = 'JSONデータにcategories配列が含まれていません';
      return;
    }

    // カテゴリデータの検証
    for (const category of data.categories) {
      if (!category.category || !category.date || !category.method) {
        error.value = 'カテゴリデータに必須フィールドが不足しています';
        return;
      }
    }

    previewData.value = data;
  } catch (e) {
    error.value = 'JSONの形式が正しくありません';
  }
};

const executeImport = () => {
  if (previewData.value) {
    isLoading.value = true;
    emit('import', previewData.value, clearExisting.value);
  }
};

// テキスト入力の監視
watch(jsonText, (newValue) => {
  if (importMethod.value === 'text') {
    validateAndPreview(newValue);
  }
});
</script>

<style scoped>
.modal-overlay {
  position: fixed;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  background: rgba(0, 0, 0, 0.5);
  display: flex;
  align-items: center;
  justify-content: center;
  z-index: 1000;
  padding: 1rem;
}

.modal-content {
  background: white;
  border-radius: 8px;
  max-width: 600px;
  width: 100%;
  max-height: 90vh;
  overflow-y: auto;
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.2);
}

.modal-header {
  padding: 1.5rem;
  border-bottom: 1px solid #e1e5e9;
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.modal-header h2 {
  margin: 0;
  color: #333;
}

.close-button {
  background: none;
  border: none;
  font-size: 1.5rem;
  cursor: pointer;
  color: #666;
  padding: 0.25rem;
  border-radius: 4px;
}

.close-button:hover {
  background: #f0f0f0;
}

.modal-body {
  padding: 1.5rem;
}

.option-group {
  margin-bottom: 1.5rem;
}

.option-group h3 {
  margin: 0 0 1rem 0;
  color: #333;
}

.radio-option,
.checkbox-option {
  display: flex;
  align-items: center;
  gap: 0.5rem;
  margin-bottom: 0.5rem;
  cursor: pointer;
}

.file-upload {
  margin-bottom: 1.5rem;
}

.file-input {
  display: none;
}

.file-drop-zone {
  border: 2px dashed #ddd;
  border-radius: 8px;
  padding: 2rem;
  text-align: center;
  transition: border-color 0.2s;
}

.file-drop-zone:hover {
  border-color: #007bff;
}

.drop-text p {
  margin: 0.5rem 0;
  color: #666;
}

.browse-button {
  background: #007bff;
  color: white;
  border: none;
  padding: 0.75rem 1.5rem;
  border-radius: 4px;
  cursor: pointer;
  font-weight: 500;
}

.browse-button:hover {
  background: #0056b3;
}

.selected-file {
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 1rem;
}

.selected-file p {
  margin: 0;
  color: #28a745;
}

.clear-button {
  background: #dc3545;
  color: white;
  border: none;
  padding: 0.5rem 1rem;
  border-radius: 4px;
  cursor: pointer;
  font-size: 0.875rem;
}

.clear-button:hover {
  background: #c82333;
}

.text-input {
  margin-bottom: 1.5rem;
}

.text-input label {
  display: block;
  margin-bottom: 0.5rem;
  font-weight: 500;
}

.json-textarea {
  width: 100%;
  padding: 0.75rem;
  border: 1px solid #ddd;
  border-radius: 4px;
  font-family: 'Courier New', monospace;
  font-size: 0.875rem;
  resize: vertical;
}

.settings {
  margin-bottom: 1.5rem;
  padding: 1rem;
  background: #f8f9fa;
  border-radius: 4px;
}

.warning-text {
  margin: 0.5rem 0 0 0;
  color: #dc3545;
  font-size: 0.875rem;
}

.preview {
  margin-bottom: 1.5rem;
  padding: 1rem;
  border: 1px solid #e3f2fd;
  background: #f3f9ff;
  border-radius: 4px;
}

.preview h4 {
  margin: 0 0 1rem 0;
  color: #1976d2;
}

.preview-stats {
  display: flex;
  gap: 1rem;
  margin-bottom: 1rem;
  flex-wrap: wrap;
}

.stat {
  background: white;
  padding: 0.5rem;
  border-radius: 4px;
  font-size: 0.875rem;
}

.preview-categories {
  display: flex;
  flex-direction: column;
  gap: 0.5rem;
}

.preview-category {
  background: white;
  padding: 0.75rem;
  border-radius: 4px;
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.more-categories {
  text-align: center;
  color: #666;
  font-style: italic;
  padding: 0.5rem;
}

.error-message {
  margin-bottom: 1rem;
  padding: 1rem;
  background: #f8d7da;
  color: #721c24;
  border: 1px solid #f5c6cb;
  border-radius: 4px;
}

.modal-footer {
  padding: 1.5rem;
  border-top: 1px solid #e1e5e9;
  display: flex;
  gap: 1rem;
  justify-content: flex-end;
}

.btn-primary,
.btn-secondary {
  padding: 0.75rem 1.5rem;
  border: none;
  border-radius: 4px;
  font-weight: 500;
  cursor: pointer;
  transition: all 0.2s;
}

.btn-primary {
  background: #007bff;
  color: white;
}

.btn-primary:hover:not(:disabled) {
  background: #0056b3;
}

.btn-primary:disabled {
  background: #ccc;
  cursor: not-allowed;
}

.btn-secondary {
  background: #6c757d;
  color: white;
}

.btn-secondary:hover {
  background: #545b62;
}

@media (max-width: 768px) {
  .modal-content {
    margin: 0.5rem;
    max-height: 95vh;
  }
  
  .modal-header,
  .modal-body,
  .modal-footer {
    padding: 1rem;
  }
  
  .modal-footer {
    flex-direction: column;
  }
  
  .preview-stats {
    flex-direction: column;
  }
}
</style>
