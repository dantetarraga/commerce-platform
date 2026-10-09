import { mutationOptions } from '@tanstack/react-query'
import { queryKeys } from '@/app/api'
import { cancelOrder } from '../actions/orders.actions'

export const cancelOrderMutation = (orderId: string) =>
  mutationOptions({
    mutationFn: (reason: string) => cancelOrder(orderId, reason),
    onSuccess: async (order, _reason, _result, { client }) => {
      client.setQueryData(queryKeys.orders.detail(orderId), order)
      await client.invalidateQueries({ queryKey: queryKeys.orders.all() })
    },
  })
