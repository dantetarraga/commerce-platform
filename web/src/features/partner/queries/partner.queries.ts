import { queryOptions } from '@tanstack/react-query'
import { queryKeys } from '@/app/api'
import { getDaySummary, getSalesReport, getSettlement } from '../actions/partner.actions'
import type { DateRange } from '../model/partner'

export const daySummaryQuery = (date: string) =>
  queryOptions({
    queryKey: queryKeys.partnerSummary(date),
    queryFn: ({ signal }) => getDaySummary(date, signal),
    // El día en curso cambia con cada pedido.
    refetchInterval: 60_000,
  })

export const salesReportQuery = (range: DateRange, storeId: string) =>
  queryOptions({
    queryKey: queryKeys.partnerReport({ ...range, storeId }),
    queryFn: ({ signal }) => getSalesReport(range, storeId, signal),
  })

export const settlementQuery = (range: DateRange, storeId: string) =>
  queryOptions({
    queryKey: queryKeys.partnerSettlement({ ...range, storeId }),
    queryFn: ({ signal }) => getSettlement(range, storeId, signal),
  })
