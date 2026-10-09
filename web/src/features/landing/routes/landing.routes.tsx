import { AccountDeletionPage } from '../pages/account-deletion.page'
import { LandingPage } from '../pages/landing.page'
import { PrivacyPage, TermsPage } from '../pages/legal.page'

export const landingRoute = { path: '/', component: LandingPage } as const

/** URL que se declara en Google Play para la eliminación de cuentas. */
export const accountDeletionRoute = {
  path: '/account-deletion',
  component: AccountDeletionPage,
} as const

/** URLs públicas de la política de privacidad y los términos (Google Play las pide). */
export const privacyRoute = { path: '/privacy', component: PrivacyPage } as const
export const termsRoute = { path: '/terms', component: TermsPage } as const
