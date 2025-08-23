import type { DayOfWeek } from '@/types'

/**
 * 今日の曜日から始まる曜日配列を返す
 */
export function sortDaysStartingToday(): DayOfWeek[] {
  const allDays: DayOfWeek[] = ['Monday','Tuesday','Wednesday','Thursday','Friday','Saturday','Sunday']
  
  const today = new Date()
  const todayDayIndex = today.getDay() // 0=Sunday, 1=Monday, ..., 6=Saturday
  
  // JavaScript の getDay() を DayOfWeek 配列のインデックスに変換
  // getDay(): 0=Sunday, 1=Monday, 2=Tuesday, 3=Wednesday, 4=Thursday, 5=Friday, 6=Saturday
  // allDays: [Monday, Tuesday, Wednesday, Thursday, Friday, Saturday, Sunday]
  const dayIndexMapping = [6, 0, 1, 2, 3, 4, 5] // [Sunday->6, Monday->0, Tuesday->1, ...]
  const todayIndex = dayIndexMapping[todayDayIndex]
  
  // 今日の曜日から始まる配列に並び替え
  return [
    ...allDays.slice(todayIndex),
    ...allDays.slice(0, todayIndex)
  ]
}

/**
 * 指定された曜日の今週の日付を取得する
 * @param dayOfWeek 曜日
 * @returns YYYY-MM-DD形式の日付文字列
 */
export function getThisWeekDate(dayOfWeek: DayOfWeek | string): string {
  //指定された曜日のソート済み配列でのインデックスを取得
  const today = new Date()
  const SortedWeek = sortDaysStartingToday()
  const targetDayIndex = SortedWeek.findIndex(day => day === dayOfWeek)

  // 今週の指定曜日の日付を計算
  const targetDate = new Date(today)
  targetDate.setDate(today.getDate() + targetDayIndex)
  
  // YYYY-MM-DD形式で返す
  return targetDate.toISOString().split('T')[0]
}

/**
 * 今日の曜日を DayOfWeek 型で取得する
 */
export function getTodayDayOfWeek(): DayOfWeek {
  const today = new Date()
  const todayDayIndex = today.getDay()
  
  const dayNames: DayOfWeek[] = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday']
  return dayNames[todayDayIndex]
}
