import { AdminHomePage } from '../pages/admin-home.page'
import { MerchantHomePage } from '../pages/merchant-home.page'

export const adminHomeRoute = { path: '/', component: AdminHomePage } as const
export const merchantHomeRoute = { path: '/', component: MerchantHomePage } as const
