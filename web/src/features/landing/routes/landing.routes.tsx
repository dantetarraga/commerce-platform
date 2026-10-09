import { AccountDeletionPage } from '../pages/account-deletion.page'
import { LandingPage } from '../pages/landing.page'

export const landingRoute = { path: '/', component: LandingPage } as const

/** URL que se declara en Google Play para la eliminación de cuentas. */
export const accountDeletionRoute = {
  path: '/account-deletion',
  component: AccountDeletionPage,
} as const
