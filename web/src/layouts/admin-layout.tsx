import { navigation } from '@/app/config/navigation'
import { PortalLayout } from './portal-layout'

export function AdminLayout() {
  return <PortalLayout portal={navigation.ADMIN} roleLabel='Equipo Apamuy' />
}
