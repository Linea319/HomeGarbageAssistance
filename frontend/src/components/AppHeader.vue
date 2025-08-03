<!--
  ヘッダーコンポーネント
  現在の日付表示とハンバーガーメニューを管理する
-->
<template>
  <header class="header">
    <div class="header-content">
      <div class="date-info">
        <h1 class="date">{{ currentDate }}</h1>
        <p class="day">{{ currentDay }}</p>
      </div>
      
      <button 
        class="hamburger-menu"
        @click="toggleMenu"
        :class="{ active: isMenuOpen }"
        aria-label="メニューを開く"
      >
        <span></span>
        <span></span>
        <span></span>
      </button>
    </div>
    
    <!-- ハンバーガーメニューの内容 -->
    <div class="menu-overlay" v-if="isMenuOpen" @click="closeMenu">
      <div class="menu-content" @click.stop>
        <h2>ゴミ検索</h2>
        <div class="search-container">
          <input
            v-model="searchQuery"
            @input="onSearchInput"
            @keyup.enter="performSearch"
            type="text"
            placeholder="ゴミの種類を入力してください"
            class="search-input"
          />
          <button @click="performSearch" class="search-button">
            検索
          </button>
        </div>
        
        <!-- 検索結果表示 -->
        <div v-if="searchResults.length > 0" class="search-results">
          <h3>検索結果</h3>
          <div 
            v-for="result in searchResults" 
            :key="result.garbage_type.id"
            class="search-result-item"
            @click="selectCategory(result.category)"
          >
            <div class="garbage-name">{{ result.garbage_type.name }}</div>
            <div class="category-info">
              <span class="category">{{ result.category.category }}</span>
              <span class="day">{{ getDayInJapanese(result.category.date) }}</span>
            </div>
          </div>
        </div>
        
        <div v-else-if="searchQuery && !loading" class="no-results">
          検索結果が見つかりませんでした
        </div>
        
        <div v-if="loading" class="loading">
          検索中...
        </div>
      </div>
    </div>
  </header>
</template>

<script setup lang="ts">
import { ref, computed, onMounted } from 'vue';
import { useGarbageApi } from '@/composables/useGarbageApi';
import type { GarbageCategory, SearchResult } from '@/types';
import { DAYS_JP } from '@/types';

// Props and Emits
const emit = defineEmits<{
  categorySelected: [category: GarbageCategory];
}>();

// Reactive data
const isMenuOpen = ref(false);
const searchQuery = ref('');
const searchResults = ref<SearchResult[]>([]);

// API composable
const { searchGarbageType, loading } = useGarbageApi();

// Computed properties
const currentDate = computed(() => {
  const now = new Date();
  return `${now.getFullYear()}年${now.getMonth() + 1}月${now.getDate()}日`;
});

const currentDay = computed(() => {
  const now = new Date();
  const dayNames = ['日曜日', '月曜日', '火曜日', '水曜日', '木曜日', '金曜日', '土曜日'];
  return dayNames[now.getDay()];
});

// Methods
function toggleMenu() {
  isMenuOpen.value = !isMenuOpen.value;
  if (!isMenuOpen.value) {
    searchQuery.value = '';
    searchResults.value = [];
  }
}

function closeMenu() {
  isMenuOpen.value = false;
  searchQuery.value = '';
  searchResults.value = [];
}

function onSearchInput() {
  // リアルタイム検索の場合はここで実装
  // 現在はEnterキーまたは検索ボタンでのみ検索実行
}

async function performSearch() {
  if (!searchQuery.value.trim()) return;
  
  try {
    const results = await searchGarbageType(searchQuery.value);
    searchResults.value = results;
  } catch (error) {
    console.error('検索エラー:', error);
  }
}

function selectCategory(category: GarbageCategory) {
  emit('categorySelected', category);
  closeMenu();
}

function getDayInJapanese(englishDay: string): string {
  return DAYS_JP[englishDay as keyof typeof DAYS_JP] || englishDay;
}

// Lifecycle
onMounted(() => {
  // 必要に応じて初期化処理
});
</script>

<style scoped>
.header {
  background: linear-gradient(135deg, #4CAF50, #45a049);
  color: white;
  position: sticky;
  top: 0;
  z-index: 1000;
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.1);
}

.header-content {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 1rem;
  max-width: 1200px;
  margin: 0 auto;
}

.date-info {
  flex: 1;
}

.date {
  font-size: 1.5rem;
  font-weight: bold;
  margin: 0;
}

.day {
  font-size: 1rem;
  margin: 0.25rem 0 0 0;
  opacity: 0.9;
}

.hamburger-menu {
  background: none;
  border: none;
  cursor: pointer;
  display: flex;
  flex-direction: column;
  justify-content: space-around;
  width: 2rem;
  height: 2rem;
  padding: 0;
}

.hamburger-menu span {
  width: 100%;
  height: 3px;
  background-color: white;
  border-radius: 2px;
  transition: all 0.3s ease;
}

.hamburger-menu.active span:nth-child(1) {
  transform: rotate(45deg) translate(5px, 5px);
}

.hamburger-menu.active span:nth-child(2) {
  opacity: 0;
}

.hamburger-menu.active span:nth-child(3) {
  transform: rotate(-45deg) translate(7px, -6px);
}

.menu-overlay {
  position: fixed;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  background-color: rgba(0, 0, 0, 0.5);
  z-index: 1001;
  display: flex;
  justify-content: center;
  align-items: flex-start;
  padding-top: 5rem;
}

.menu-content {
  background: white;
  color: #333;
  border-radius: 8px;
  padding: 2rem;
  max-width: 90%;
  width: 400px;
  max-height: 80vh;
  overflow-y: auto;
  box-shadow: 0 4px 20px rgba(0, 0, 0, 0.15);
}

.menu-content h2 {
  margin: 0 0 1rem 0;
  color: #4CAF50;
}

.search-container {
  display: flex;
  gap: 0.5rem;
  margin-bottom: 1rem;
}

.search-input {
  flex: 1;
  padding: 0.75rem;
  border: 2px solid #ddd;
  border-radius: 4px;
  font-size: 1rem;
}

.search-input:focus {
  outline: none;
  border-color: #4CAF50;
}

.search-button {
  padding: 0.75rem 1.5rem;
  background-color: #4CAF50;
  color: white;
  border: none;
  border-radius: 4px;
  cursor: pointer;
  font-size: 1rem;
}

.search-button:hover {
  background-color: #45a049;
}

.search-results {
  margin-top: 1rem;
}

.search-results h3 {
  margin: 0 0 0.5rem 0;
  color: #333;
}

.search-result-item {
  padding: 0.75rem;
  border: 1px solid #ddd;
  border-radius: 4px;
  margin-bottom: 0.5rem;
  cursor: pointer;
  transition: all 0.2s ease;
}

.search-result-item:hover {
  background-color: #f5f5f5;
  border-color: #4CAF50;
}

.garbage-name {
  font-weight: bold;
  margin-bottom: 0.25rem;
}

.category-info {
  display: flex;
  gap: 0.5rem;
  font-size: 0.9rem;
  color: #666;
}

.category {
  background-color: #e8f5e8;
  color: #4CAF50;
  padding: 0.2rem 0.5rem;
  border-radius: 12px;
  font-size: 0.8rem;
}

.no-results,
.loading {
  text-align: center;
  padding: 1rem;
  color: #666;
}

@media (max-width: 768px) {
  .header-content {
    padding: 0.75rem;
  }
  
  .date {
    font-size: 1.25rem;
  }
  
  .menu-content {
    margin: 1rem;
    padding: 1.5rem;
    width: auto;
  }
}
</style>
