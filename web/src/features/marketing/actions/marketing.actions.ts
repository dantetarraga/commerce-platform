import { http } from '@/app/api'
import type { Coupon, Promotion } from '../model/marketing'
import type { couponPayload, promotionPayload } from '../schemas/marketing.schemas'

export type CouponPayload = ReturnType<typeof couponPayload>
export type PromotionPayload = ReturnType<typeof promotionPayload>

export async function getCoupons(signal?: AbortSignal) {
  return (await http.get<Coupon[]>('/admin/coupons', { signal })).data
}

export async function createCoupon(payload: CouponPayload) {
  return (await http.post<Coupon>('/admin/coupons', payload)).data
}

/** El código no se cambia: los pedidos y los banners lo referencian. */
export async function updateCoupon(
  id: string,
  { code: _code, ...payload }: Partial<CouponPayload>,
) {
  return (await http.patch<Coupon>(`/admin/coupons/${id}`, payload)).data
}

export async function getPromotions(cityId?: string, signal?: AbortSignal) {
  return (
    await http.get<Promotion[]>('/admin/promotions', {
      params: cityId ? { cityId } : undefined,
      signal,
    })
  ).data
}

export async function createPromotion(payload: PromotionPayload) {
  return (await http.post<Promotion>('/admin/promotions', payload)).data
}

export async function updatePromotion(id: string, payload: Partial<PromotionPayload>) {
  return (await http.patch<Promotion>(`/admin/promotions/${id}`, payload)).data
}

export async function deletePromotion(id: string) {
  await http.delete(`/admin/promotions/${id}`)
}
