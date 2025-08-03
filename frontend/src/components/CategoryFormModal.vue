<!-- カテゴリフォームモーダル -->
<template>
  <div class="modal-overlay" @click="$emit('cancel')">
    <div class="modal-content" @click.stop>
      <div class="modal-header">
        <h2>{{ category ? 'カテゴリ編集' : '新規カテゴリ作成' }}</h2>
        <button @click="emit('cancel')" class="close-button">✕</button>
      </div>

      <form @submit.prevent="save" class="modal-body">
        <div class="form-group">
          <label for="category">カテゴリ名 *</label>
          <input
            id="category"
            v-model="formData.category"
            type="text"
            required
            placeholder="例: 可燃ゴミ"
          />
        </div>

        <div class="form-group">
          <label>回収曜日 *</label>
          <div class="days-selection">
            <label 
              v-for="day in daysOfWeek" 
              :key="day.value"
              class="day-checkbox"
            >
              <input
                type="checkbox"
                :value="day.value"
                v-model="formData.selectedDays"
              />
              <span class="checkmark">{{ day.label }}</span>
            </label>
          </div>
        </div>

        <div class="form-group">
          <label for="method">回収方法 *</label>
          <textarea
            id="method"
            v-model="formData.method"
            required
            placeholder="例: 専用ゴミ袋に入れて出してください"
            rows="3"
          ></textarea>
        </div>

        <div class="form-group">
          <label for="notion">注意事項</label>
          <textarea
            id="notion"
            v-model="formData.notion"
            placeholder="例: 生ごみは水気をよく切ってから出してください"
            rows="2"
          ></textarea>
        </div>

        <div class="form-group">
          <label>特別回収日</label>
          <div class="special-days">
            <div
              v-for="(_, index) in formData.special_days"
              :key="index"
              class="special-day-item"
            >
              <input
                v-model="formData.special_days[index]"
                type="date"
                class="date-input"
              />
              <button
                type="button"
                @click="removeSpecialDay(index)"
                class="remove-button"
              >
                ✕
              </button>
            </div>
            <button
              type="button"
              @click="addSpecialDay"
              class="add-button"
            >
              ➕ 特別回収日を追加
            </button>
          </div>
        </div>

        <div class="form-group">
          <label>ゴミ種類</label>
          <div class="garbage-types">
            <div
              v-for="(_, index) in formData.garbage_types"
              :key="index"
              class="garbage-type-item"
            >
              <input
                v-model="formData.garbage_types[index]"
                type="text"
                placeholder="例: 生ごみ"
                class="type-input"
              />
              <button
                type="button"
                @click="removeGarbageType(index)"
                class="remove-button"
              >
                ✕
              </button>
            </div>
            <button
              type="button"
              @click="addGarbageType"
              class="add-button"
            >
              ➕ ゴミ種類を追加
            </button>
          </div>
        </div>

        <div class="modal-footer">
          <button type="button" @click="emit('cancel')" class="btn-secondary">
            キャンセル
          </button>
          <button type="submit" class="btn-primary" :disabled="!isValid">
            {{ category ? '更新' : '作成' }}
          </button>
        </div>
      </form>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, onMounted } from 'vue';
import type { CategoryData, CategoryFormData } from '../composables/useAdminApi';

interface Props {
  category?: CategoryData | null;
}

const props = defineProps<Props>();

const emit = defineEmits<{
  save: [data: CategoryFormData];
  cancel: [];
}>();

// 曜日の選択肢
const daysOfWeek = [
  { value: 'Monday', label: '月曜日' },
  { value: 'Tuesday', label: '火曜日' },
  { value: 'Wednesday', label: '水曜日' },
  { value: 'Thursday', label: '木曜日' },
  { value: 'Friday', label: '金曜日' },
  { value: 'Saturday', label: '土曜日' },
  { value: 'Sunday', label: '日曜日' }
];

const formData = ref<CategoryFormData & { selectedDays: string[] }>({
  category: '',
  date: '',
  selectedDays: [],
  method: '',
  special_days: [],
  notion: '',
  garbage_types: ['']
});

const isValid = computed(() => {
  return formData.value.category.trim() && 
         formData.value.selectedDays.length > 0 && 
         formData.value.method.trim();
});

const addSpecialDay = () => {
  formData.value.special_days.push('');
};

const removeSpecialDay = (index: number) => {
  formData.value.special_days.splice(index, 1);
};

const addGarbageType = () => {
  formData.value.garbage_types.push('');
};

const removeGarbageType = (index: number) => {
  if (formData.value.garbage_types.length > 1) {
    formData.value.garbage_types.splice(index, 1);
  }
};

const save = () => {
  if (isValid.value) {
    // 空の要素を除去
    const cleanData: CategoryFormData = {
      category: formData.value.category,
      date: formData.value.selectedDays, // 複数曜日を配列として送信
      method: formData.value.method,
      special_days: formData.value.special_days.filter(day => day.trim()),
      notion: formData.value.notion,
      garbage_types: formData.value.garbage_types.filter(type => type.trim())
    };
    emit('save', cleanData);
  }
};

onMounted(() => {
  if (props.category) {
    // 既存カテゴリの場合、dateを配列として扱う
    const categoryDays = Array.isArray(props.category.date) 
      ? props.category.date 
      : [props.category.date];
    
    formData.value = {
      category: props.category.category,
      date: props.category.date,
      selectedDays: categoryDays,
      method: props.category.method,
      special_days: [...(props.category.special_days || [])],
      notion: props.category.notion || '',
      garbage_types: props.category.garbage_types?.map(t => t.name) || ['']
    };
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

.form-group {
  margin-bottom: 1.5rem;
}

.form-group label {
  display: block;
  margin-bottom: 0.5rem;
  font-weight: 500;
  color: #333;
}

.form-group input,
.form-group select,
.form-group textarea {
  width: 100%;
  padding: 0.75rem;
  border: 1px solid #ddd;
  border-radius: 4px;
  font-size: 1rem;
  transition: border-color 0.2s;
}

.form-group input:focus,
.form-group select:focus,
.form-group textarea:focus {
  outline: none;
  border-color: #007bff;
  box-shadow: 0 0 0 2px rgba(0, 123, 255, 0.1);
}

.days-selection {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(100px, 1fr));
  gap: 0.5rem;
  margin-top: 0.5rem;
}

.day-checkbox {
  display: flex;
  align-items: center;
  cursor: pointer;
  padding: 0.5rem;
  border: 1px solid #ddd;
  border-radius: 4px;
  transition: all 0.2s;
  background: white;
}

.day-checkbox:hover {
  background-color: #f5f5f5;
}

.day-checkbox input[type="checkbox"] {
  display: none;
}

.day-checkbox input[type="checkbox"]:checked + .checkmark {
  background-color: #4CAF50;
  color: white;
}

.checkmark {
  flex: 1;
  text-align: center;
  padding: 0.25rem;
  border-radius: 3px;
  transition: all 0.2s;
  font-size: 0.875rem;
}

.special-days,
.garbage-types {
  display: flex;
  flex-direction: column;
  gap: 0.5rem;
}

.special-day-item,
.garbage-type-item {
  display: flex;
  gap: 0.5rem;
  align-items: center;
}

.date-input,
.type-input {
  flex: 1;
  margin: 0;
}

.remove-button {
  background: #dc3545;
  color: white;
  border: none;
  padding: 0.5rem;
  border-radius: 4px;
  cursor: pointer;
  font-size: 0.875rem;
  min-width: 2rem;
}

.remove-button:hover {
  background: #c82333;
}

.add-button {
  background: #28a745;
  color: white;
  border: none;
  padding: 0.5rem 1rem;
  border-radius: 4px;
  cursor: pointer;
  font-size: 0.875rem;
  align-self: flex-start;
}

.add-button:hover {
  background: #218838;
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
}
</style>
