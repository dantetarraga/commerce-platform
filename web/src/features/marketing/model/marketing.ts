import { formatMoney, type Money } from '@/lib/money'

export type CouponType = 'PERCENTAGE' | 'FIXED_AMOUNT' | 'FREE_DELIVERY'

export interface Coupon {
  id: string
  code: string
  label: string
  description: string | null
  type: CouponType
  percentOff: number | null
  amountOff: Money | null
  maxDiscount: Money | null
  minOrderAmount: Money
  cityId: string | null
  storeId: string | null
  startsAt: string
  endsAt: string
  usageLimit: number | null
  perUserLimit: number
  firstOrderOnly: boolean
  usedCount: number
  isActive: boolean
}

export interface Promotion {
  id: string
  cityId: string
  storeId: string | null
  couponId: string | null
  title: string
  subtitle: string | null
  imageUrl: string
  startsAt: string
  endsAt: string
  sortOrder: number
  isActive: boolean
}

export type CampaignStatus = 'active' | 'scheduled' | 'expired' | 'inactive' | 'exhausted'

export const CAMPAIGN_STATUS_LABEL: Record<CampaignStatus, string> = {
  active: 'Vigente',
  scheduled: 'Programado',
  expired: 'Vencido',
  inactive: 'Desactivado',
  exhausted: 'Agotado',
}

/** Estado según el interruptor, el periodo y, en cupones, los usos. */
export function campaignStatus(
  item: Pick<Coupon, 'isActive' | 'startsAt' | 'endsAt'> &
    Partial<Pick<Coupon, 'usageLimit' | 'usedCount'>>,
  now: Date = new Date(),
): CampaignStatus {
  if (!item.isActive) return 'inactive'
  if (new Date(item.endsAt) <= now) return 'expired'
  if (item.usageLimit != null && (item.usedCount ?? 0) >= item.usageLimit) return 'exhausted'
  if (new Date(item.startsAt) > now) return 'scheduled'
  return 'active'
}

/** "10 % (tope S/ 15.00)", "S/ 5.00" o "Envío gratis". */
export function describeDiscount(coupon: Coupon): string {
  switch (coupon.type) {
    case 'PERCENTAGE':
      return coupon.maxDiscount
        ? `${coupon.percentOff} % (tope ${formatMoney(coupon.maxDiscount)})`
        : `${coupon.percentOff} %`
    case 'FIXED_AMOUNT':
      return coupon.amountOff ? formatMoney(coupon.amountOff) : '—'
    case 'FREE_DELIVERY':
      return 'Envío gratis'
  }
}
