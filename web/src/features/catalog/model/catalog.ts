import type { Money } from '@/lib/money'

export interface Category {
  id: string
  name: string
  slug: string
  iconUrl: string | null
}
export interface MenuSection {
  id: string
  name: string
  sortOrder: number
}
export interface Schedule {
  dayOfWeek: number
  opensAt: number
  closesAt: number
}
export interface Product {
  id: string
  name: string
  description: string | null
  imageUrl: string | null
  basePrice: Money
  menuSectionId: string | null
  stock: number | null
  sortOrder: number
  isAvailable: boolean
  isFeatured: boolean
  isLocal: boolean
  variants: { id: string; name: string; price: Money; isAvailable: boolean }[]
  options: {
    id: string
    name: string
    minSelect: number
    maxSelect: number
    values: { id: string; name: string; priceDelta: Money; isAvailable: boolean }[]
  }[]
}

export interface StoreDetail {
  id: string
  cityId: string
  ownerId: string
  name: string
  addressLine: string
  latitude: number
  longitude: number
  description: string | null
  phone: string | null
  logoUrl: string | null
  coverUrl: string | null
  minOrderAmount: Money
  avgPrepMinutes: number
  categoryIds: string[]
  isActive: boolean
  isAcceptingOrders: boolean
  schedules: Schedule[]
  sections: MenuSection[]
  products: Product[]
}

export const WEEK_DAYS = ['Domingo', 'Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado']
export function minutesToTime(minutes: number) {
  return `${String(Math.floor(minutes / 60)).padStart(2, '0')}:${String(minutes % 60).padStart(2, '0')}`
}
export function timeToMinutes(time: string) {
  const [hours, minutes] = time.split(':').map(Number)
  return hours * 60 + minutes
}
