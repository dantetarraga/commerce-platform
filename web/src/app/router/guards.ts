import { redirect, type ParsedLocation } from '@tanstack/react-router'
import {
  getCurrentUser,
  hasAnyRole,
  panelHomeFor,
  restoreSession,
  type PanelRole,
} from '@/features/auth'

async function currentUser() {
  await restoreSession()
  return getCurrentUser()
}

export function requireRole(...roles: PanelRole[]) {
  return async ({ location }: { location: ParsedLocation }) => {
    const user = await currentUser()
    if (!user) throw redirect({ to: '/ingresar', search: { redirect: location.href } })
    if (!hasAnyRole(user, roles)) throw redirect({ to: panelHomeFor(user) ?? '/ingresar' })
  }
}

export async function redirectToHome(): Promise<never> {
  const user = await currentUser()
  throw redirect({ to: (user && panelHomeFor(user)) ?? '/ingresar' })
}

export async function redirectIfSignedIn() {
  const user = await currentUser()
  const home = user && panelHomeFor(user)
  if (home) throw redirect({ to: home })
}
