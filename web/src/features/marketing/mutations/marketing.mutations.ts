import { mutationOptions, type QueryClient } from '@tanstack/react-query'
import { queryKeys } from '@/app/api'
import {
  createCoupon,
  createPromotion,
  deletePromotion,
  updateCoupon,
  updatePromotion,
  type CouponPayload,
  type PromotionPayload,
} from '../actions/marketing.actions'

const refreshCoupons = (client: QueryClient) =>
  client.invalidateQueries({ queryKey: queryKeys.coupons() })

const refreshPromotions = (client: QueryClient) =>
  client.invalidateQueries({ queryKey: queryKeys.promotions.all() })

export const saveCouponMutation = (couponId?: string) =>
  mutationOptions({
    mutationFn: (payload: CouponPayload) =>
      couponId ? updateCoupon(couponId, payload) : createCoupon(payload),
    onSuccess: (_data, _payload, _result, { client }) => refreshCoupons(client),
  })

export const toggleCouponMutation = (couponId: string, isActive: boolean) =>
  mutationOptions({
    mutationFn: async () => {
      await updateCoupon(couponId, { isActive: !isActive })
    },
    onSuccess: (_data, _vars, _result, { client }) => refreshCoupons(client),
  })

export const savePromotionMutation = (promotionId?: string) =>
  mutationOptions({
    mutationFn: (payload: PromotionPayload) =>
      promotionId ? updatePromotion(promotionId, payload) : createPromotion(payload),
    onSuccess: (_data, _payload, _result, { client }) => refreshPromotions(client),
  })

export const deletePromotionMutation = (promotionId: string) =>
  mutationOptions({
    mutationFn: () => deletePromotion(promotionId),
    onSuccess: (_data, _vars, _result, { client }) => refreshPromotions(client),
  })
