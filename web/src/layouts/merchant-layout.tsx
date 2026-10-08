import { navigation } from '@/app/config/navigation'
import { PortalLayout } from './portal-layout'

export function MerchantLayout() {
  return <PortalLayout portal={navigation.MERCHANT} roleLabel='Socio' />
}
