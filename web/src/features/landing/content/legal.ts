import privacy from './privacidad.md?raw'
import terms from './terminos.md?raw'

/**
 * Copias de `mobile/assets/legal`, la fuente que muestran las apps. Se editan allá y
 * se copian aquí; `legal.test.ts` falla si se separan.
 */
export const legalDocuments = {
  privacy: {
    slug: 'privacidad',
    path: '/privacy',
    title: 'Política de privacidad',
    markdown: privacy,
  },
  terms: { slug: 'terminos', path: '/terms', title: 'Términos y condiciones', markdown: terms },
} as const

export type LegalDocumentKey = keyof typeof legalDocuments

/** Los textos se enlazan entre sí con `apamuy:<slug>`, igual que en las apps. */
export function legalHref(href: string): string | undefined {
  if (!href.startsWith('apamuy:')) return undefined
  const slug = href.slice('apamuy:'.length)
  return Object.values(legalDocuments).find((doc) => doc.slug === slug)?.path
}
