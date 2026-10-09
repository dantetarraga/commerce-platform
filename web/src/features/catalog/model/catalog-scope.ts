import { createContext } from 'react'

/**
 * Quién edita el catálogo: el equipo Apamuy (cualquier negocio, todo) o el dueño desde
 * el Portal Socios (solo lo suyo; nombre, dirección, publicación y dueño los decide Apamuy).
 */
export type CatalogScope = 'admin' | 'merchant'

/** Prefijo de los endpoints de edición según quién edita. */
export const catalogBase = (scope: CatalogScope) =>
  scope === 'admin' ? '/admin' : '/merchant/catalog'

export const CatalogScopeContext = createContext<CatalogScope>('admin')
