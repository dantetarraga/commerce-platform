import { mutationOptions } from '@tanstack/react-query'
import { queryKeys } from '@/app/api'
import { markSettlementPaid, setCommission } from '../actions/settlements.actions'

// Los negocios sin comisión propia muestran la por defecto en su ficha.
export const saveCommissionMutation = () =>
  mutationOptions({
    // La comisión por defecto no se quita: su formulario nunca manda `null`.
    mutationFn: async (rateBps: number | null) => {
      if (rateBps !== null) await setCommission(rateBps)
    },
    onSuccess: (_data, _rate, _result, { client }) =>
      Promise.all([
        client.invalidateQueries({ queryKey: queryKeys.commission() }),
        client.invalidateQueries({ queryKey: queryKeys.storeCommission.all() }),
      ]),
  })

export const markSettlementPaidMutation = (storeId: string, week: string) =>
  mutationOptions({
    mutationFn: () => markSettlementPaid(storeId, week),
    onSuccess: (_data, _vars, _result, { client }) =>
      Promise.all([
        client.invalidateQueries({ queryKey: queryKeys.settlements.all() }),
        client.invalidateQueries({ queryKey: queryKeys.partnerWeeklySettlement.all() }),
      ]),
  })
