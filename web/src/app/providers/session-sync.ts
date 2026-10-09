import { sessionStore, syncSessionAcrossTabs } from '@/features/auth'
import type { AppRouter } from '../router/router'

/**
 * Al perder la sesión (cerrar sesión, refresh rechazado u otra pestaña), las guardas
 * vuelven a correr y sacan al usuario de las rutas protegidas.
 */
export function setupSessionSync(router: AppRouter) {
  const stopTabSync = syncSessionAcrossTabs()
  const stopGuardSync = sessionStore.subscribe((state, previous) => {
    if (previous.status === 'authenticated' && state.status !== 'authenticated') {
      void router.invalidate()
    }
  })
  return () => {
    stopTabSync()
    stopGuardSync()
  }
}
