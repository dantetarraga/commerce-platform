import type { LinkProps } from '@tanstack/react-router'
import {
  Banknote,
  ChartColumn,
  ClipboardList,
  LayoutDashboard,
  MapPinned,
  Megaphone,
  Store,
  UtensilsCrossed,
  Users,
  type LucideIcon,
} from 'lucide-react'

export interface NavItem {
  label: string
  icon: LucideIcon
  /** Sin `to`: módulo planificado, se muestra como "Pronto". */
  to?: LinkProps['to']
}

export interface NavPortal {
  label: string
  items: NavItem[]
}

export const navigation = {
  ADMIN: {
    label: 'Administración',
    items: [
      { label: 'Inicio', icon: LayoutDashboard, to: '/admin' },
      { label: 'Pedidos', icon: ClipboardList },
      { label: 'Socios', icon: Users, to: '/admin/partners' },
      { label: 'Catálogo', icon: UtensilsCrossed, to: '/admin/catalog' },
      { label: 'Marketing', icon: Megaphone },
      { label: 'Ciudades', icon: MapPinned },
      { label: 'Caja', icon: Banknote },
    ],
  },
  MERCHANT: {
    label: 'Portal Socios',
    items: [
      { label: 'Inicio', icon: LayoutDashboard, to: '/partner' },
      { label: 'Mi tienda', icon: Store },
      { label: 'Menú', icon: UtensilsCrossed },
      { label: 'Reportes', icon: ChartColumn },
      { label: 'Rendición', icon: Banknote },
    ],
  },
} satisfies Record<'ADMIN' | 'MERCHANT', NavPortal>
