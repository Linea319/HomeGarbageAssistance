import type { DayOfWeek } from '@/types';

export type DayTheme = {
  DateColor: string; // ヘッダー色とカードアクセント色を統一
  badgeBg: string;
  badgeText: string;
};

export const DAY_THEMES: Record<DayOfWeek, DayTheme> = {
  Sunday: {
    DateColor: '#ec4188ff',
    badgeBg: '#FDECEA',
    badgeText: '#C62828',
  },
  Monday: {
    DateColor: '#ccb013ff',
    badgeBg: '#f7f4d3ff',
    badgeText: '#85550eff',
  },
  Tuesday: {
    DateColor: '#c01515ff',
    badgeBg: '#f7dfdfff',
    badgeText: '#a10d0dff',
  },
  Wednesday: {
    DateColor: '#2371b9ff',
    badgeBg: '#e5eff5ff',
    badgeText: '#143e8cff',
  },
  Thursday: {
    DateColor: '#ef8700cb',
    badgeBg: '#FFF3E0',
    badgeText: '#E65100',
  },
  Friday: {
    DateColor: '#8418c2ff',
    badgeBg: '#fce4f9ff',
    badgeText: '#8214adff',
  },
  Saturday: {
    DateColor: '#00695C',
    badgeBg: '#E0F2F1',
    badgeText: '#004D40',
  },
};

export function getThemeForDay(day: DayOfWeek | string): DayTheme {
  const key = String(day) as DayOfWeek;
  return DAY_THEMES[key] ?? DAY_THEMES.Monday;
}
