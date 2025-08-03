<!--
  曜日別ゴミカードコンポーネント
  各曜日のゴミ回収情報を表示する
-->
<template>
  <div 
    class="garbage-card"
    :class="{ 
      active: isActive, 
      expanded: isExpanded,
      today: isToday 
    }"
    @click="handleCardClick"
  >
    <div class="card-header">
      <h2 class="day-title">{{ getDayInJapanese(category.date) }}</h2>
      <div v-if="category.special_days.length > 0" class="special-badge">
        特別回収日あり
      </div>
    </div>
    
    <div class="card-content">
      <div class="category-name">{{ category.category }}</div>
      
      <!-- 基本情報 -->
      <div class="basic-info">
        <div class="method">
          <span class="label">回収方法:</span>
          <span class="value">{{ category.method }}</span>
        </div>
      </div>
      
      <!-- 展開時の詳細情報 -->
      <div v-if="isExpanded" class="detailed-info">
        <!-- 特別回収日 -->
        <div v-if="category.special_days.length > 0" class="special-days">
          <span class="label">特別回収日:</span>
          <div class="special-days-list">
            <span 
              v-for="day in category.special_days" 
              :key="day"
              class="special-day"
            >
              {{ formatSpecialDay(day) }}
            </span>
          </div>
        </div>
        
        <!-- 注意事項 -->
        <div v-if="category.notion" class="notion">
          <span class="label">注意事項:</span>
          <p class="notion-text">{{ category.notion }}</p>
        </div>
        
        <!-- ゴミ種類一覧 -->
        <div v-if="category.garbage_types.length > 0" class="garbage-types">
          <span class="label">対象ゴミ:</span>
          <div class="types-list">
            <span 
              v-for="type in category.garbage_types" 
              :key="type.id"
              class="garbage-type"
            >
              {{ type.name }}
            </span>
          </div>
        </div>
      </div>
      
      <!-- 展開ボタン -->
      <div class="expand-hint" v-if="!isExpanded">
        <span>タップで詳細を表示</span>
        <svg 
          width="16" 
          height="16" 
          viewBox="0 0 24 24" 
          fill="currentColor"
        >
          <path d="M12 15.5l-6-6h12l-6 6z"/>
        </svg>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { computed } from 'vue';
import type { GarbageCategory } from '@/types';
import { DAYS_JP } from '@/types';

// Props
interface Props {
  category: GarbageCategory;
  isActive: boolean;
  isExpanded: boolean;
  isToday?: boolean;
}

const props = defineProps<Props>();

// Emits
const emit = defineEmits<{
  cardClick: [category: GarbageCategory];
}>();

// Methods
function handleCardClick() {
  emit('cardClick', props.category);
}

function getDayInJapanese(englishDay: string): string {
  return DAYS_JP[englishDay as keyof typeof DAYS_JP] || englishDay;
}

function formatSpecialDay(dateString: string): string {
  try {
    // ISO形式の日付文字列を想定
    const date = new Date(dateString);
    return `${date.getMonth() + 1}/${date.getDate()}`;
  } catch {
    // パースに失敗した場合はそのまま返す
    return dateString;
  }
}

// Computed
const cardClasses = computed(() => ({
  'garbage-card': true,
  'active': props.isActive,
  'expanded': props.isExpanded,
  'today': props.isToday
}));
</script>

<style scoped>
.garbage-card {
  background: white;
  border-radius: 12px;
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.1);
  margin: 0.5rem;
  padding: 1.5rem;
  cursor: pointer;
  transition: all 0.3s ease;
  border: 2px solid transparent;
  min-height: 120px;
}

.garbage-card:hover {
  box-shadow: 0 4px 16px rgba(0, 0, 0, 0.15);
  transform: translateY(-2px);
}

.garbage-card.active {
  border-color: #4CAF50;
  box-shadow: 0 4px 20px rgba(76, 175, 80, 0.3);
}

.garbage-card.today {
  background: linear-gradient(135deg, #e8f5e8, #f1f8e9);
  border-color: #4CAF50;
}

.garbage-card.expanded {
  min-height: auto;
}

.card-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 1rem;
}

.day-title {
  font-size: 1.5rem;
  font-weight: bold;
  color: #2E7D32;
  margin: 0;
}

.special-badge {
  background-color: #FF9800;
  color: white;
  padding: 0.25rem 0.75rem;
  border-radius: 12px;
  font-size: 0.75rem;
  font-weight: bold;
}

.card-content {
  display: flex;
  flex-direction: column;
  gap: 1rem;
}

.category-name {
  font-size: 1.25rem;
  font-weight: bold;
  color: #333;
  background-color: #f0f7f0;
  padding: 0.75rem;
  border-radius: 8px;
  text-align: center;
}

.basic-info {
  display: flex;
  flex-direction: column;
  gap: 0.5rem;
}

.method {
  display: flex;
  flex-direction: column;
  gap: 0.25rem;
}

.label {
  font-weight: bold;
  color: #4CAF50;
  font-size: 0.9rem;
}

.value {
  color: #333;
  line-height: 1.4;
}

.detailed-info {
  padding-top: 1rem;
  border-top: 1px solid #e0e0e0;
  display: flex;
  flex-direction: column;
  gap: 1rem;
}

.special-days {
  display: flex;
  flex-direction: column;
  gap: 0.5rem;
}

.special-days-list {
  display: flex;
  flex-wrap: wrap;
  gap: 0.5rem;
}

.special-day {
  background-color: #FFF3E0;
  color: #FF9800;
  padding: 0.25rem 0.75rem;
  border-radius: 12px;
  font-size: 0.9rem;
  font-weight: bold;
}

.notion {
  display: flex;
  flex-direction: column;
  gap: 0.5rem;
}

.notion-text {
  color: #666;
  line-height: 1.5;
  margin: 0;
  padding: 0.75rem;
  background-color: #f9f9f9;
  border-radius: 6px;
}

.garbage-types {
  display: flex;
  flex-direction: column;
  gap: 0.5rem;
}

.types-list {
  display: flex;
  flex-wrap: wrap;
  gap: 0.5rem;
}

.garbage-type {
  background-color: #e3f2fd;
  color: #1976d2;
  padding: 0.25rem 0.75rem;
  border-radius: 12px;
  font-size: 0.9rem;
}

.expand-hint {
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 0.5rem;
  color: #999;
  font-size: 0.9rem;
  margin-top: 0.5rem;
  padding: 0.5rem;
}

.expand-hint svg {
  opacity: 0.6;
}

/* レスポンシブ対応 */
@media (max-width: 768px) {
  .garbage-card {
    margin: 0.25rem;
    padding: 1rem;
  }
  
  .day-title {
    font-size: 1.25rem;
  }
  
  .category-name {
    font-size: 1.1rem;
    padding: 0.5rem;
  }
  
  .special-badge {
    font-size: 0.7rem;
    padding: 0.2rem 0.5rem;
  }
}

/* スクロール時の最適化 */
.garbage-card:not(.active):not(.expanded) {
  transform: scale(0.95);
  opacity: 0.8;
}

.garbage-card.active:not(.expanded) {
  transform: scale(1.02);
}
</style>
