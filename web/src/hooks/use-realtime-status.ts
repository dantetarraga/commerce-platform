import { useEffect, useEffectEvent, useSyncExternalStore } from 'react'
import { realtime } from '@/app/api'

/** `reconnecting`: el tiempo real se cayó y Socket.IO está reintentando. */
export function useRealtimeStatus() {
  return useSyncExternalStore(realtime.subscribeStatus, () => realtime.status)
}

/** Corre [handler] cada vez que vuelve la conexión, para recuperar lo que no llegó. */
export function useRealtimeReconnect(handler: () => void) {
  const onReconnect = useEffectEvent(handler)
  useEffect(() => realtime.onReconnect(onReconnect), [])
}
