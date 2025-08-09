<!--
  メインアプリケーションコンポーネント
  全体のレイアウトと状態管理を行う
-->
<template>
  <div id="app" class="app">
    <!-- 管理パネル -->
    <AdminPanel 
      v-if="showAdminPanel"
      @close="closeAdminPanel"
    />
    
    <!-- メイン画面 -->
    <div v-else>
      <!-- ヘッダー -->
      <AppHeader 
        @category-selected="onCategorySelected" 
        @open-data-management="openDataManagement"
      />
      
      <!-- メイン画面 -->
      <main class="main-content">
      <div v-if="loading" class="loading-container">
        <div class="loading-spinner"></div>
        <p>読み込み中...</p>
      </div>
      
      <div v-else-if="error" class="error-container">
        <div class="error-message">
          <h3>エラーが発生しました</h3>
          <p>{{ error }}</p>
          <button @click="retryLoad" class="retry-button">
            再試行
          </button>
        </div>
      </div>
      
      <div v-else class="cards-container">
        <!-- 曜日カード一覧（曜日ごとに1枚） -->
        <div 
          class="cards-scroll"
          ref="cardsScrollRef"
          @wheel="handleWheel"
        >
          <DayCard
            v-for="day in daysOfWeek"
            :key="day"
            :day="day"
            :categories="categoriesByDay[day] || []"
            :is-today="todayDay === day"
          />
        </div>
        
        <!-- 翌日の情報表示 -->
        <div v-if="tomorrowCategories.length > 0" class="tomorrow-info">
          <h3>翌日のゴミ回収</h3>
          <div class="tomorrow-cards">
            <div 
              v-for="category in tomorrowCategories"
              :key="`tomorrow-${category.id}`"
              class="tomorrow-card"
            >
              <span class="tomorrow-category">{{ category.category }}</span>
            </div>
          </div>
        </div>
      </div>
    </main>
    
    <!-- 検索結果ポップアップ -->
    <div 
      v-if="showSearchPopup && selectedSearchResult" 
      class="search-popup-overlay"
      @click="closeSearchPopup"
    >
      <div class="search-popup" @click.stop>
        <div class="popup-header">
          <h3>検索結果</h3>
          <button @click="closeSearchPopup" class="close-button">×</button>
        </div>
        <div class="popup-content">
          <div class="found-item">
            <h4>{{ selectedSearchResult.garbage_type.name }}</h4>
            <div class="item-details">
              <span class="category">{{ selectedSearchResult.category.category }}</span>
              <span v-for="date in selectedSearchResult.category.date" class="day">{{ getDayInJapanese(date) }}</span>
            </div>
            <div class="method">
              <strong>回収方法:</strong> {{ selectedSearchResult.category.method }}
            </div>
            <div v-if="selectedSearchResult.category.notion" class="notion">
              <strong>注意事項:</strong> {{ selectedSearchResult.category.notion }}
            </div>
          </div>
        </div>
      </div>
    </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted, computed, nextTick, watch } from 'vue';
import AppHeader from '@/components/AppHeader.vue';
import GarbageCard from '@/components/GarbageCard.vue';
import AdminPanel from '@/components/AdminPanel.vue';
import DayCard from '@/components/DayCard.vue';
import { useGarbageApi } from '@/composables/useGarbageApi';
import type { GarbageCategory, SearchResult, DayOfWeek } from '@/types';
import { DAYS_JP, getDaysAsArray } from '@/types';

// Reactive data
const allCategories = ref<GarbageCategory[]>([]);
const activeCardId = ref<number | null>(null);
const expandedCardId = ref<number | null>(null);
const showSearchPopup = ref(false);
const selectedSearchResult = ref<SearchResult | null>(null);
const cardsScrollRef = ref<HTMLElement | null>(null);
const todayDay = ref<string>('');
const showAdminPanel = ref(false);

// API composable
const { 
  getAllCategories, 
  getTodayCategories, 
  loading, 
  error 
} = useGarbageApi();

const daysOfWeek: DayOfWeek[] = ['Monday','Tuesday','Wednesday','Thursday','Friday','Saturday','Sunday']

// 曜日 -> カテゴリ一覧 のマップ
const categoriesByDay = computed<Record<string, GarbageCategory[]>>(() => {
  const map: Record<string, GarbageCategory[]> = {
    Monday: [], Tuesday: [], Wednesday: [], Thursday: [], Friday: [], Saturday: [], Sunday: []
  }
  for (const cat of allCategories.value) {
    const days = Array.isArray(cat.date) ? cat.date : [cat.date]
    for (const d of days) {
      if (!map[d]) map[d] = []
      map[d].push(cat)
    }
  }
  return map
})

// Computed properties
const tomorrowCategories = computed(() => {
  if (!todayDay.value) return []
  const idx = daysOfWeek.indexOf(todayDay.value as DayOfWeek)
  const next = daysOfWeek[(idx + 1) % 7]
  return categoriesByDay.value[next] || []
})

// Methods
async function loadData() {
  try {
    // 今日のカテゴリ情報を取得
    const todayResult = await getTodayCategories();
    todayDay.value = todayResult.today;
    
    // 全カテゴリを取得
    const categories = await getAllCategories();
    allCategories.value = categories;
    
    // 今日のカードを初期選択
    if (todayResult.data.length > 0) {
      activeCardId.value = todayResult.data[0].id;
      await nextTick();
      scrollToActiveCard();
    } else if (categories.length > 0) {
      activeCardId.value = categories[0].id;
    }
  } catch (err) {
    console.error('データ読み込みエラー:', err);
  }
}

async function retryLoad() {
  await loadData();
}

function onCardClick(category: GarbageCategory) {
  if (expandedCardId.value === category.id) {
    // 既に展開されている場合は折りたたむ
    expandedCardId.value = null;
  } else {
    // 新しいカードを展開
    expandedCardId.value = category.id;
    activeCardId.value = category.id;
  }
}

function onCategorySelected(category: GarbageCategory) {
  // 検索からのカテゴリ選択
  activeCardId.value = category.id;
  expandedCardId.value = category.id;
  
  // 該当カードまでスクロール
  scrollToActiveCard();
  
  // 検索結果ポップアップを表示
  selectedSearchResult.value = {
    garbage_type: category.garbage_types[0] || { id: 0, name: '', category_id: category.id },
    category: category
  };
  showSearchPopup.value = true;
}

function openDataManagement() {
  showAdminPanel.value = true;
}

function closeAdminPanel() {
  showAdminPanel.value = false;
}

function closeSearchPopup() {
  showSearchPopup.value = false;
  selectedSearchResult.value = null;
}

function isTodayCard(category: GarbageCategory): boolean {
  // 複数曜日対応：今日の曜日が含まれるかチェック
  const catDays = Array.isArray(category.date) ? category.date : [category.date];
  return catDays.includes(todayDay.value);
}

function getDayInJapanese(englishDay: string): string {
  return DAYS_JP[englishDay as keyof typeof DAYS_JP] || englishDay;
}

function handleWheel(event: WheelEvent) {
  // 横スクロールの実装
  if (cardsScrollRef.value) {
    event.preventDefault();
    cardsScrollRef.value.scrollTop += event.deltaY;
  }
}

function scrollToActiveCard() {
  if (!activeCardId.value || !cardsScrollRef.value) return;
  
  nextTick(() => {
    const activeCard = cardsScrollRef.value?.querySelector('.garbage-card.active');
    if (activeCard) {
      activeCard.scrollIntoView({
        behavior: 'smooth',
        block: 'center'
      });
    }
  });
}

// Watchers
watch(activeCardId, () => {
  scrollToActiveCard();
});

// Lifecycle
onMounted(() => {
  loadData();
});
</script>

<style scoped>
.app {
  min-height: 100vh;
  background: linear-gradient(180deg, #f0f7f0, #e8f5e8);
  font-family: 'Helvetica Neue', Arial, 'Hiragino Kaku Gothic ProN', 'Hiragino Sans', Meiryo, sans-serif;
}

.main-content {
  padding: 1rem;
  max-width: 1200px;
  margin: 0 auto;
}

.loading-container,
.error-container {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  min-height: 50vh;
  text-align: center;
}

.loading-spinner {
  width: 50px;
  height: 50px;
  border: 4px solid #f3f3f3;
  border-top: 4px solid #4CAF50;
  border-radius: 50%;
  animation: spin 1s linear infinite;
  margin-bottom: 1rem;
}

@keyframes spin {
  0% { transform: rotate(0deg); }
  100% { transform: rotate(360deg); }
}

.error-message {
  background: white;
  padding: 2rem;
  border-radius: 12px;
  box-shadow: 0 4px 20px rgba(0, 0, 0, 0.1);
  max-width: 400px;
}

.retry-button {
  background-color: #4CAF50;
  color: white;
  border: none;
  padding: 0.75rem 1.5rem;
  border-radius: 6px;
  cursor: pointer;
  font-size: 1rem;
  margin-top: 1rem;
}

.retry-button:hover {
  background-color: #45a049;
}

.cards-container {
  display: flex;
  flex-direction: column;
  gap: 2rem;
}

.cards-scroll {
  max-height: 70vh;
  overflow-y: auto;
  padding: 0.5rem;
  scroll-behavior: smooth;
}

.cards-scroll::-webkit-scrollbar {
  width: 8px;
}

.cards-scroll::-webkit-scrollbar-track {
  background: rgba(0, 0, 0, 0.1);
  border-radius: 4px;
}

.cards-scroll::-webkit-scrollbar-thumb {
  background: #4CAF50;
  border-radius: 4px;
}

.tomorrow-info {
  background: white;
  border-radius: 12px;
  padding: 1.5rem;
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.1);
}

.tomorrow-info h3 {
  margin: 0 0 1rem 0;
  color: #4CAF50;
  font-size: 1.25rem;
}

.tomorrow-cards {
  display: flex;
  flex-wrap: wrap;
  gap: 1rem;
}

.tomorrow-card {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 0.5rem;
  background: #f0f7f0;
  padding: 1rem;
  border-radius: 8px;
  min-width: 120px;
}

.tomorrow-category {
  font-weight: bold;
  color: #2E7D32;
}

.tomorrow-day {
  color: #666;
  font-size: 0.9rem;
}

.search-popup-overlay {
  position: fixed;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  background-color: rgba(0, 0, 0, 0.5);
  z-index: 2000;
  display: flex;
  justify-content: center;
  align-items: center;
  padding: 1rem;
}

.search-popup {
  background: white;
  border-radius: 12px;
  max-width: 500px;
  width: 100%;
  max-height: 80vh;
  overflow-y: auto;
  box-shadow: 0 4px 20px rgba(0, 0, 0, 0.2);
}

.popup-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 1.5rem;
  border-bottom: 1px solid #e0e0e0;
}

.popup-header h3 {
  margin: 0;
  color: #4CAF50;
}

.close-button {
  background: none;
  border: none;
  font-size: 1.5rem;
  cursor: pointer;
  color: #666;
  padding: 0;
  width: 30px;
  height: 30px;
  border-radius: 50%;
  display: flex;
  align-items: center;
  justify-content: center;
}

.close-button:hover {
  background-color: #f0f0f0;
}

.popup-content {
  padding: 1.5rem;
}

.found-item h4 {
  margin: 0 0 1rem 0;
  color: #333;
  font-size: 1.25rem;
}

.item-details {
  display: flex;
  gap: 1rem;
  margin-bottom: 1rem;
}

.category {
  background-color: #e8f5e8;
  color: #4CAF50;
  padding: 0.5rem 1rem;
  border-radius: 12px;
  font-weight: bold;
}

.day {
  background-color: #e3f2fd;
  color: #1976d2;
  padding: 0.5rem 1rem;
  border-radius: 12px;
  font-weight: bold;
}

.method,
.notion {
  margin-bottom: 1rem;
  line-height: 1.5;
}

/* レスポンシブ対応 */
@media (max-width: 768px) {
  .main-content {
    padding: 0.5rem;
  }
  
  .cards-scroll {
    max-height: 60vh;
  }
  
  .tomorrow-cards {
    justify-content: center;
  }
  
  .search-popup {
    margin: 0.5rem;
  }
  
  .popup-header,
  .popup-content {
    padding: 1rem;
  }
  
  .item-details {
    flex-direction: column;
    gap: 0.5rem;
  }
}
</style>
