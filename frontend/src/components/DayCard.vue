<template>
  <div 
    class="day-card"
    :class="{ today: isToday }"
    :style="styleVars"
  >
    <div class="card-header">
      <div class="header-title">
        <h2 class="day-title">{{ dayLabel }}</h2>
        <span class="date-subtitle">{{ dateLabel }}</span>
      </div>
      <div v-if="categories.length > 0" class="count-badge">{{ categories.length }}</div>
    </div>

    <div class="card-content">
      <div v-if="categories.length === 0" class="empty">回収予定のカテゴリはありません</div>

      <div 
        v-for="cat in categories" 
        :key="cat.id" 
        class="category-item"
        :class="{ 
          expanded: expandedIds.has(cat.id),
          'grayed-out': shouldGrayOut(cat.special_days, props.day)
        }"
      >
        <button class="category-header" @click="toggle(cat.id)">
          <div class="header-content">
            <span class="category-name">{{ cat.category }}</span>
            <span 
              v-if="cat.special_days && cat.special_days.length > 0"
              class="special-day-icon"
            >
              特別回収日
            </span>
          </div>
          <span class="chevron" :class="{ open: expandedIds.has(cat.id) }">▾</span>
        </button>

        <div v-if="expandedIds.has(cat.id)" class="category-details">
          <div class="detail-row">
            <span class="label">回収方法</span>
            <span class="value">{{ cat.method }}</span>
          </div>

          <div v-if="cat.notion" class="detail-row">
            <span class="label">注意事項</span>
            <span class="value">{{ cat.notion }}</span>
          </div>

          <div v-if="cat.garbage_types && cat.garbage_types.length" class="detail-row">
            <span class="label">対象</span>
            <div class="chips">
              <span v-for="t in cat.garbage_types" :key="t.id || t.name" class="chip">{{ t.name }}</span>
            </div>
          </div>

          <div v-if="cat.special_days && cat.special_days.length" class="detail-row">
            <span class="label">特別回収日</span>
            <div class="chips">
              <span v-for="d in cat.special_days" :key="d" class="chip">{{ formatSpecialDay(d) }}</span>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { computed, ref } from 'vue'
import type { GarbageCategory, DayOfWeek } from '@/types'
import { DAYS_JP } from '@/types'
import { getThemeForDay } from '@/constants/dayThemes'
import { getThisWeekDate } from '@/utils/dateUtils'

interface Props {
  day: DayOfWeek | string
  categories: GarbageCategory[]
  isToday?: boolean
}
const props = defineProps<Props>()

const expandedIds = ref<Set<number>>(new Set())

const dayLabel = computed(() => DAYS_JP[props.day as DayOfWeek] || String(props.day))

// 日付ラベルを計算
const dateLabel = computed(() => {
  const thisWeekDate = getThisWeekDate(props.day)
  if (!thisWeekDate) return ''
  
  const date = new Date(thisWeekDate)
  const month = date.getMonth() + 1
  const day = date.getDate()
  return `${month}/${day}`
})

// テーマ色をCSS変数として供給（<<DateColor>> で統一）
const theme = computed(() => getThemeForDay(props.day))
const styleVars = computed(() => ({
  '--DateColor': theme.value.DateColor,
  '--badge-bg': theme.value.badgeBg,
  '--badge-text': theme.value.badgeText,
} as Record<string, string>))

function toggle(id: number) {
  if (expandedIds.value.has(id)) expandedIds.value.delete(id)
  else expandedIds.value.add(id)
}

function isSpecialDayThisWeek(specialDays: string[], dayOfWeek: DayOfWeek | string): boolean {
  // 特別回収日が設定されていない場合はfalse
  if (!specialDays || specialDays.length === 0) return false
  
  // 今週の該当曜日の日付を取得
  const thisWeekDate = getThisWeekDate(dayOfWeek)
  if (!thisWeekDate) return false
  
  // 特別回収日に今週の該当曜日が含まれているかチェック
  return specialDays.includes(thisWeekDate)
}

function shouldGrayOut(specialDays: string[], dayOfWeek: DayOfWeek | string): boolean {
  // 特別回収日が設定されていない場合はfalse
  if (!specialDays || specialDays.length === 0) return false

  // 特別回収日に今週の該当曜日が含まれているかチェック
  return !isSpecialDayThisWeek(specialDays, dayOfWeek)
}

function formatSpecialDay(dateString: string): string {
  try {
    const date = new Date(dateString)
    const m = date.getMonth() + 1
    const d = date.getDate()
    return `${m}/${d}`
  } catch {
    return dateString
  }
}
</script>

<style scoped>
.day-card {
  background: #fff;
  border-radius: 12px;
  box-shadow: 0 4px 14px rgba(0,0,0,0.08);
  padding: 1rem;
  margin-bottom: 1rem;
  border: 1px solid #eef2ee;
  border-left: 6px solid var(--DateColor);
}
.day-card.today {
  border-color: var(--DateColor);
  box-shadow: 0 6px 18px rgba(0,0,0,0.12);
}
.card-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  margin-bottom: 0.5rem;
}
.header-title {
  display: flex;
  align-items: baseline;
  gap: 0.5rem;
}
.day-title {
  margin: 0;
  font-size: 1.25rem;
  color: var(--DateColor);
}
.date-subtitle {
  font-size: 1rem;
  font-weight: 700;
  color: var(--DateColor);
}
.count-badge {
  background: var(--badge-bg);
  color: var(--badge-text);
  border-radius: 999px;
  padding: 0.1rem 0.5rem;
  font-size: 0.85rem;
}
.empty {
  color: #7f8c8d;
  font-size: 0.95rem;
}
.category-item {
  border-top: 1px dashed #e5e7eb;
  transition: opacity 0.3s ease;
}
.category-item:first-of-type { border-top: none; }
.category-item.grayed-out {
  opacity: 0.4;
}
.category-item.grayed-out .category-name {
  color: #9ca3af;
}
.category-item.grayed-out .special-day-icon {
  background: linear-gradient(135deg, #9ca3af, #6b7280);
  box-shadow: 0 2px 4px rgba(156, 163, 175, 0.3);
}
.category-header {
  width: 100%;
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 0.6rem 0;
  background: transparent;
  border: none;
  cursor: pointer;
  font-size: 1rem;
}
.header-content {
  display: flex;
  align-items: center;
  gap: 0.5rem;
  flex: 1;
}
.category-name { font-weight: 600; color: #34495e; }
.special-day-icon {
  background: linear-gradient(135deg, #ff6b6b, #ff5722);
  color: white;
  font-size: 0.75rem;
  font-weight: 500;
  padding: 0.2rem 0.5rem;
  border-radius: 6px;
  white-space: nowrap;
  box-shadow: 0 2px 4px rgba(255, 107, 107, 0.3);
}
.chevron { transition: transform .2s ease; }
.chevron.open { transform: rotate(180deg); }
.category-details { padding: 0 0 0.6rem 0; }
.detail-row { display:flex; gap: .5rem; margin: .25rem 0; align-items: flex-start; }
.label { min-width: 6rem; color: #6b7280; font-size: .9rem; }
.value { color: #2c3e50; }
.chips { display: flex; gap: .4rem; flex-wrap: wrap; }
.chip { background: #f1f5f9; padding: .15rem .5rem; border-radius: 999px; font-size: .85rem; }
</style>
