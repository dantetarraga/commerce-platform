import { useEffect, useEffectEvent } from 'react'
import { realtime } from '@/app/api'

/** Escucha un evento del backend mientras el componente está montado. */
export function useRealtimeEvent<T>(event: string, handler: (payload: T) => void) {
  const onEvent = useEffectEvent((payload: unknown) => handler(payload as T))
  useEffect(() => realtime.subscribe(event, onEvent), [event])
}
