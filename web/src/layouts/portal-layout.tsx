import { Outlet } from '@tanstack/react-router'
import { AppShell } from '@/components/layout/app-shell'
import type { NavPortal } from '@/config/navigation'
import { displayName, initials, useCurrentUser, useSignOut } from '@/features/auth'

interface PortalLayoutProps {
  portal: NavPortal
  roleLabel: string
}

export function PortalLayout({ portal, roleLabel }: PortalLayoutProps) {
  const user = useCurrentUser()
  const signOut = useSignOut()
  if (!user) return null

  return (
    <AppShell
      portal={portal}
      user={{
        name: displayName(user),
        initials: initials(user),
        roleLabel,
        avatarUrl: user.avatarUrl,
      }}
      onSignOut={signOut}
    >
      <Outlet />
    </AppShell>
  )
}
